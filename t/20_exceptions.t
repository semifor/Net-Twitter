#!perl
use warnings;
use strict;
use Test::More;
use Test::Fatal;
use JSON qw/to_json/;
use lib qw(t/lib);
use Net::Twitter;

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required for tests' if $@;

my $nt = Net::Twitter->new(
    traits   => [qw/API::REST/],
    username => 'homer',
    password => 'doh!',
);

my $t = TestUA->new(1, $nt->ua);

my $response = HTTP::Response->new(404, 'Not Found');
$response->content(to_json({
    request => '/direct_messages/destroy/456.json',
    error   => 'No direct message with that ID found.',
}));
$t->response($response);

eval { $nt->destroy_direct_message(456) };
my $message = '$@ valid after stringification';
if( $@ ) {
    ok $@, $message;
}
else {
   fail $message;
}

{
    my $e = exception { $nt->destroy_direct_message(456) };
    isa_ok $e, 'Net::Twitter::Error';
    like   $e, qr/No direct message/,    'error stringifies';
    is     $e->http_response->code, 404, "respose code";
    is     $e->code, 404,                'http_response handles code';
    like   $e->twitter_error->{request}, qr/456.json/, 'twitter_error request';
    is     $e, $e->error,                'stringifies to $@->error';
}

# simulate a 500 response returned by LWP::UserAgent when it can't make a connection
$response = HTTP::Response->new(500, "Can't connect to api.twitter.com:80");
$response->content("<html>foo</html>");
$t->response($response);

{
    my $e = exception { $nt->friends_timeline({ since_id => 500_000_000 }) };
    isa_ok  $e, 'Net::Twitter::Error';
    like    $e->http_response->content, qr/html/, 'html content';
}

done_testing;
