#!perl
use warnings;
use strict;
use Try::Tiny;
use Test::More tests => 1;
use Net::Twitter;

eval "use LWP::UserAgent 5.819";
plan skip_all => 'LWP::UserAgent >= 5.819 required' if $@;

my $req;
my $ua = LWP::UserAgent->new;
$ua->add_handler(request_send => sub {
    $req = shift;
    my $res = HTTP::Response->new(500, 'Uh-oh!');
    $res->content('{"test":"OK"}');
    return $res;
});

sub params {
    my $uri = URI->new;
    $uri->query($req->content);
    my %params = $uri->query_form;
    return \%params;
}

my $retry_count = 0;
my $nt = Net::Twitter->new(
    traits   => [qw/API::REST RetryOnError/],
    username => 'fred',
    password => 'secret',
    ua       => $ua,
    max_retries => 5,
    retry_delay_code => sub { ++$retry_count },
);

try { $nt->verify_credentials };
is $retry_count, 5, 'retried 5 times';
