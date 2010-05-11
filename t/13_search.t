#!perl
use warnings;
use strict;
use Test::More;
use lib qw(t/lib);

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

plan tests => 5;

use Net::Twitter;

my $nt = Net::Twitter->new(traits => [qw/API::Search/]);

my $request;
my %args;
my $response = HTTP::Response->new(200, 'OK');
$response->content('{"test":"success"}');

$nt->ua->add_handler(request_send => sub {
    $request = shift;

    $response->request($request);
    %args = $request->uri->query_form;

    return $response;
});

my $search_term = "intelligent life";
my $r = $nt->search($search_term);
isa_ok $r,       'HASH',       "result is expected type";
is     $args{q}, $search_term, "param q has search term";

# additional args in a HASH ref
$r = $nt->search($search_term, { page => 2 });
is $args{page}, 2, "page parameter set";

like $request->uri, qr(/search.twitter.com/), 'search endpoint';

$nt->trends;
like $request->uri, qr(/api.twitter.com/1/), 'trends endpoint';
