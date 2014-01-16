#!perl
use warnings;
use strict;
use HTTP::Response;
use Test::More;
use Test::Warn;
use lib qw(t/lib);

plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

plan tests => 6;

use Net::Twitter;

my $nt = Net::Twitter->new(ssl => 0, traits => [qw/API::Search API::REST/]);

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

warnings_like { $nt->trends } qr/deprecated/i;
like $request->uri, qr(/api.twitter.com/1/), 'trends endpoint';
