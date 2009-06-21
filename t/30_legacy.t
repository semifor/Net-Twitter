#!perl
use warnings;
use strict;
use Test::Exception;
use Test::More tests => 5;
use lib qw(t/lib);

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required for tests' if $@;

BEGIN { use_ok 'Net::Twitter', qw/Legacy/ }

my $nt  = Net::Twitter->new;
my $t   = TestUA->new($nt->ua);
my $msg = 'Test failure';

my $r = $nt->update_twittervision(90210);
ok !defined $r && !defined $nt->get_error, 'update_twittervision squelched';

$nt->twittervision(1);
ok $nt->update_twittervision(90210), 'update_twittervision called';

$t->response(HTTP::Response->new(500, $msg));

lives_ok { $nt->public_timeline } 'exception trapped';
is       $nt->http_message, $msg, 'http_message';

exit 0;
