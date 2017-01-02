#!perl
use warnings;
use strict;
use URI;
use Net::Twitter;
use Net::OAuth::Message;
use Test::More;

plan tests => 2;

# Ensure post args are encoded per the OAuth spec
#
# We assume Net::OAuth does the right thing, here.
#
# Bug reported by Nick Andrew (@elronxenu) 2013-02-27

my $nt = Net::Twitter->new(
    ssl                 => 0,
    traits              => [qw/API::RESTv1_1/],
    consumer_key        => 'mykey',
    consumer_secret     => 'mysecret',
    access_token        => 'mytoken',
    access_token_secret => 'mytokensecret',
);

my $req;
$nt->ua->add_handler(request_send => sub {
    $req = shift;
    my $res = HTTP::Response->new(200, 'OK');
    $res->content('{}');

    return $res;
});

my $text = q[Bob's your !@##$%^&*(){}} uncle!];
$nt->new_direct_message({ screen_name => 'perl_api', text => $text });

my $encoded_text = Net::OAuth::Message::encode($text);
like $req->content, qr/\Q$encoded_text/, 'properly encoded';

my $uri = URI->new($req->uri);
$uri->query($req->content);
my %params = $uri->query_form;
is $params{text}, $text, 'decoded text matches';
