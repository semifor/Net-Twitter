#!perl
use warnings;
use strict;
use Test::More;
use Test::Fatal;

use Net::Twitter;

plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

my $nt = Net::Twitter->new(
    traits          => [ qw/AppAuth API::RESTv1_1/ ],
    consumer_key    => 'my-key',
    consumer_secret => 'my-secret',
    ssl             => 1,
);
isa_ok $nt, 'Net::Twitter';

my ( $req, $res );
$nt->ua->add_handler(request_send => sub { $req = shift; $res });

$res = HTTP::Response->new(200, 'OK');
$res->content('{"access_token":"my-token","token_type":"bearer"}');

$nt->request_access_token;
ok $nt->authorized, 'has an access token';
is $nt->access_token, 'my-token', 'with the correct value';

done_testing;
