#!perl
use warnings;
use strict;

use Test::More tests => 1;

use Net::Twitter;

# For end_session, on success, twitter returns status code 200 and an ERROR
# payload!!!

my $nt = Net::Twitter->new(legacy => 0);
$nt->ua->add_handler(request_send => sub {
    my ($request, $ua, $h) = @_;

    my $res = HTTP::Response->new(200, 'OK');
    $res->content('{"error":"Logged out.","request":"/account/end_session.json"}');
    $res->request($request);

    return $res;
});


# This test will always succeed since we're spoofing the response
# from Twitter. It's simply meant to demonstrate Twitter's behavior.
# Should we thorw an error, or should we return the HASH?
my $r = eval { $nt->end_session };
like $@, qr/Logged out/, 'error on success';
