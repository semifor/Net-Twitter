#!perl
use warnings;
use strict;
use Scalar::Util qw/blessed/;
use Test::More;
use lib qw(t/lib);

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

plan tests => 7;

use_ok 'Net::Twitter';

my $nt = Net::Twitter->new(traits => [qw/API::REST InflateObjects/]);

my $dt = DateTime->now;
$dt->subtract(minutes => 6);

my $t = TestUA->new($nt->ua);
$t->response->content(JSON::Any->to_json([{
    text => 'Hello, twittersphere!',
    user => {
       screen_name => 'net_twitter',
    },
    created_at => $nt->_dt_parser->format_datetime($dt),
}]));

my $r = $nt->friends_timeline;
ok ref $r eq 'ARRAY', 'got an ArrayRef';

my $object = $r->[0];
ok     blessed $object, 'value is an object';
can_ok $object, qw/text user created_at relative_created_at/;
isa_ok $object->created_at,          'DateTime',      'DateTime inflation';
is     $object->relative_created_at, '6 minutes ago', 'relative_created_at';
is     $object->user->screen_name,   'net_twitter',   'nested objects';
