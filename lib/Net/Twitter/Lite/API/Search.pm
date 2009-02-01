package Net::Twitter::Lite::API::Search;

use Moose;
use Carp;

with 'Net::Twitter::Lite::API';

sub base_url { 'http://search.twitter.com' }

sub definition {[

    [ 'Search Methods' => [


        [ search => {
            description => <<'',
Returns tweets that match a specified query.  You can use a variety of search operators in your query.

            path     => 'search',
            method   => 'GET',
            params   => [qw/q lang rpp page since_id geocode show_user/],
            required => [qw/q/],
            returns  => 'ArrayRef[Status]',
        }],


        [ trends => {
            description => <<'',
Returns the top ten queries that are currently trending on Twitter.  The response includes the time of the request, the name of each trending topic, and the url to the Twitter Search results page for that topic.

            path     => 'trends',
            method   => 'GET',
            params   => [qw//],
            required => [qw//],
            returns  => 'ArrayRef[Query]',
        }],
    ]],
]}

__PACKAGE__->make_immutable;

1;
