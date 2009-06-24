#!perl
use warnings;
use strict;
use Test::More tests => 1;
use lib qw(t/lib);

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required for tests' if $@;

use Net::Twitter;

# For end_session, on success, twitter returns status code 200 and an ERROR
# payload!!!

my $nt = Net::Twitter->new(legacy => 0, username => 'me', password => 'secret');
my $t  = TestUA->new($nt->ua);
$t->response->content('{"error":"Logged out.","request":"/account/end_session.json"}');

# This test will always succeed since we're spoofing the response
# from Twitter. It's simply meant to demonstrate Twitter's behavior.
# Should we thorw an error, or should we return the HASH?
my $r = eval { $nt->end_session };
like $@, qr/Logged out/, 'error on success';
