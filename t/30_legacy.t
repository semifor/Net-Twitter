#!perl
use warnings;
use strict;
use Test::Fatal;
use Test::More;
use lib qw(t/lib);

BEGIN {
    eval 'use TestUA';
    plan skip_all => 'LWP::UserAgent 5.819 required for tests' if $@;

    plan tests => 5;

    use_ok 'Net::Twitter', qw/Legacy/;
}

my $nt  = Net::Twitter->new(username => 'me', password => 'secret');
my $t   = TestUA->new(1, $nt->ua);
my $msg = 'Test failure';

my $r = $nt->update_twittervision(90210);
ok !defined $r && !defined $nt->get_error, 'update_twittervision squelched';

$nt->twittervision(1);
ok $nt->update_twittervision(90210), 'update_twittervision called';

$t->response(HTTP::Response->new(500, $msg));

is exception { $nt->public_timeline }, undef, 'exception trapped';
is       $nt->http_message, $msg, 'http_message';

exit 0;
