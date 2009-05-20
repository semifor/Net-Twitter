#!perl
use warnings;
use strict;
use Test::Exception;
use Test::More tests => 3;
use lib qw(t/lib);
use Mock::LWP::UserAgent;

BEGIN { use_ok 'Net::Twitter::Lite::Compat' }

my $nt  = Net::Twitter::Lite::Compat->new;
my $ua  = $nt->ua;
my $msg = 'Test failure';

$ua->set_response({ code => 500, message => $msg });

lives_ok { $nt->public_timeline } 'exception trapped';
is       $nt->http_message, $msg, 'http_message';

exit 0;
