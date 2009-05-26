#!perl
use warnings;
use strict;
use Test::Exception;
use Test::More qw/no_plan/;
use lib qw(t/lib);
use Mock::LWP::UserAgent;

BEGIN { use_ok 'Net::Twitter', qw/Legacy/ }

my $nt  = Net::Twitter->new;
my $ua  = $nt->ua;
my $msg = 'Test failure';

my $r = $nt->update('Hello, world!');
ok defined $r && !defined $nt->get_error, 'api call success';

$ua->set_response({ code => 500, message => $msg });

lives_ok { $r = $nt->public_timeline } 'exception trapped';
is       $nt->http_message, $msg, 'http_message';
isa_ok   $nt->get_error, 'HASH',  'get_error returns a HASH ref';
ok       !defined $r,             'result is undef';

$ua->set_response({ code => 200, message => 'fail whale', content => '<html>no json</html>' });
$r = $nt->user_timeline;
ok      !defined $r, 'result is undefined on fail whale';
isa_ok  $nt->get_error, 'HASH', 'get_error with no JSON';
ok      exists $nt->get_error->{error}, 'get_error has {error} member';

$ua->set_response({ code => 200, message => 'error with OK response', content => '{"error":"weirdness"}' });
$r = $nt->friends;
ok      !defined $r, 'error with http response 200';
isa_ok  $nt->get_error, 'HASH', 'get_error is a HASH ref on 200 error';
is      $nt->get_error->{error}, 'weirdness', '200 error has {error} member';

exit 0;
