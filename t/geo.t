#!perl
use warnings;
use strict;
use Try::Tiny;
use Test::More;
use Net::Twitter;

eval "use LWP::UserAgent 5.819";
plan skip_all => 'LWP::UserAgent >= 5.819 required' if $@;

plan tests => 2;

my $req;
my $ua = LWP::UserAgent->new;
$ua->add_handler(request_send => sub {
    $req = shift;
    my $res = HTTP::Response->new(200);
    $res->content('{"test":"OK"}');
    return $res;
});

sub params {
    my $uri = URI->new;
    $uri->query($req->content);
    my %params = $uri->query_form;
    return \%params;
}

my $nt = Net::Twitter->new(
    traits   => [qw/API::REST/],
    username => 'fred',
    password => 'secret',
    ua       => $ua,
);

my $r = $nt->update({
    status              => 'Hello, world!',
    lat                 => 37.78215,
    long                => -122.40060,
    display_coordinates => 1,
});

my $params = params();
is params()->{display_coordinates}, 'true', "1 promoted to true";

$r = $nt->update({
    status              => 'Hello, world!',
    lat                 => 37.78215,
    long                => -122.40060,
    display_coordinates => 0,
});

$params = params();
is params()->{display_coordinates}, 'false', "0 promoted to false";
