#!perl
use warnings;
use strict;
use Test::Exception;
use Test::More tests => 5;
use lib qw(t/lib);
use Mock::LWP::UserAgent;

BEGIN { use_ok 'Net::Twitter::Lite::Compat' }

my $nt  = Net::Twitter::Lite::Compat->new;
my $ua  = $nt->ua;
my $msg = 'Test failure';

my $r = $nt->update_twittervision(90210);
ok !defined $r && !defined $nt->get_error, 'update_twittervision squelched';

$nt->twittervision(1);
ok $nt->update_twittervision(90210), 'update_twittervision called';

$ua->set_response({ code => 500, message => $msg });

lives_ok { $nt->public_timeline } 'exception trapped';
is       $nt->http_message, $msg, 'http_message';

exit 0;
