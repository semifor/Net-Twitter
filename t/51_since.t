#!perl
use warnings;
use strict;
use Try::Tiny;
use Scalar::Util qw/blessed/;
use Test::More;
use JSON qw/to_json/;
use lib qw(t/lib);

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

plan tests => 8;

use_ok 'Net::Twitter';

my $nt = Net::Twitter->new(traits => [qw/API::REST API::Search RateLimit InflateObjects/]);

my $datetime_parser = do {
    no warnings 'once';
    $Net::Twitter::Role::API::REST::DATETIME_PARSER;
};

my $dt = DateTime->now;
$dt->subtract(minutes => 6);

my $t = TestUA->new(1, $nt->ua);
$t->response->content(to_json([
    {
        text => 'Hello, twittersphere!',
        id => 1234,
        created_at => $datetime_parser->format_datetime($dt),
    },
    {
        text => 'Too old',
        id => 5678,
        created_at => $datetime_parser->format_datetime($dt - DateTime::Duration->new(days => 2)),
    },
]));

my $r = $nt->friends_timeline;
ok ref $r eq 'ARRAY', 'got an ArrayRef';
cmp_ok @$r, '==', 2,  'got 2 statuses';

$r = $nt->friends_timeline({ since => $dt - DateTime::Duration->new(days => 1) });
cmp_ok @$r, '==', 1,  'filtered with DateTime';

$r = $nt->friends_timeline({ since => time - 3600*25 });
cmp_ok @$r, '==', 1,  'filtered with epoch';

$r = $nt->friends_timeline({ since => $datetime_parser->format_datetime(
            $dt - DateTime::Duration->new(hours => 25)) });
cmp_ok @$r, '==', 1,  'filtered with string in Twitter timestamp format';

my $test = 'dies on invalid since';
try {
    $r = $nt->friends_timeline({ since => 'not a date' });
    fail $test;
}
catch { pass $test };

$nt = Net::Twitter->new(traits => [qw/API::Search API::REST/]);
$nt->ua->add_handler(request_send => sub {
        my $res = HTTP::Response->new(200);
        $res->content('{"test":"done"}');
        return $res;
});

$test = 'YYYY-MM-DD';
try {
    $r = $nt->search({ q => 'perl', since => '2009-10-05' });
    pass $test;
}
catch {
    fail "$test: $_";
};
