#!perl
use warnings;
use strict;
use Test::More tests => 10;
use Test::Exception;
use lib qw(t/lib);
use Net::Twitter;

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required for tests' if $@;

my $nt = Net::Twitter->new(
    traits   => [qw/API::REST/],
    username => 'homer',
    password => 'doh!',
);

my $t = TestUA->new($nt->ua);

my $response = HTTP::Response->new(404, 'Not Found');
$response->content(JSON::Any->to_json({
    request => '/direct_messages/destroy/456.json',
    error   => 'No direct message with that ID found.',
}));
$t->response($response);

dies_ok { $nt->destroy_direct_message(456) } 'TwitterException';
my $e = $@;
isa_ok $e, 'Net::Twitter::Error';
like   $e, qr/No direct message/,    'error stringifies';
is     $e->http_response->code, 404, "respose code";
is     $e->code, 404,                'http_response handles code';
like   $e->twitter_error->{request}, qr/456.json/, 'twitter_error request';
is     $e, $e->error,                'stringifies to $@->error';



# simulate a 500 response returned by LWP::UserAgent when it can't make a connection
$response = HTTP::Response->new(500, "Can't connect to twitter.com:80");
$response->content("<html>foo</html>");
$t->response($response);

dies_ok { $nt->friends_timeline({ since_id => 500_000_000 }) } 'HttpException';
$e = $@;
isa_ok $e, 'Net::Twitter::Error';
like    $e->http_response->content, qr/html/, 'html content';

exit 0;
