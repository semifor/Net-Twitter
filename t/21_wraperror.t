#!perl
use warnings;
use strict;
use Test::Fatal;
use Test::More;
use lib qw(t/lib);

BEGIN {
    eval 'use TestUA';
    plan skip_all => 'LWP::UserAgent 5.819 required for tests' if $@;

    plan tests => 12;

    use_ok 'Net::Twitter', qw/Legacy/;
}

my $nt  = Net::Twitter->new(username => 'me', password => 'secret');
my $t   = TestUA->new($nt->ua);
my $msg = 'Test failure';

my $r = $nt->update('Hello, world!');
ok defined $r && !defined $nt->get_error, 'api call success';

$t->response(HTTP::Response->new(500, $msg));

is exception { $r = $nt->public_timeline }, undef, 'exception trapped';
is       $nt->http_message, $msg, 'http_message';
isa_ok   $nt->get_error, 'HASH',  'get_error returns a HASH ref';
ok       !defined $r,             'result is undef';

$t->response(HTTP::Response->new(200, 'fail whale'));
$t->response->content('<html>no json</html>');
$r = $nt->user_timeline;
ok      !defined $r, 'result is undefined on fail whale';
isa_ok  $nt->get_error, 'HASH', 'get_error with no JSON';
ok      exists $nt->get_error->{error}, 'get_error has {error} member';

$t->response(HTTP::Response->new(200, 'error with OK response'));
$t->response->content('{"error":"weirdness"}');
$r = $nt->friends;
ok      !defined $r, 'error with http response 200';
isa_ok  $nt->get_error, 'HASH', 'get_error is a HASH ref on 200 error';
is      $nt->get_error->{error}, 'weirdness', '200 error has {error} member';

exit 0;
