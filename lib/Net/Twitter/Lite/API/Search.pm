package Net::Twitter::Lite::API::Search;

use Moose::Role;
use Net::Twitter::Lite::API;

has search_apiurl   => ( isa => 'Str', is => 'rw', default => 'http://search.twitter.com' );

base_url 'search_apiurl';

twitter_api_method search => (
    description => <<'',
Returns tweets that match a specified query.  You can use a variety of search operators in your query.

    path     => 'search',
    method   => 'GET',
    params   => [qw/q callback lang rpp page since_id geocode show_user/],
    required => [qw/q/],
    returns  => 'ArrayRef[Status]',
);

twitter_api_method trends => (
    description => <<'',
Returns the top ten queries that are currently trending on Twitter.  The response includes the time of the request, the name of each trending topic, and the url to the Twitter Search results page for that topic.

    path     => 'trends',
    method   => 'GET',
    params   => [qw//],
    required => [qw//],
    returns  => 'ArrayRef[Query]',
);

twitter_api_method trends_current => (
    description => <<'',
Returns the curret top ten trending toppics on Twitter.  The response includes
the time of the request, the name of each trending topic, and query used on
Twitter Search results page for that topic.

    path     => 'trends/current',
    method   => 'GET',
    params   => [qw/exclude/],
    required => [qw//],
    returns  => 'HashRef',
);

twitter_api_method trends_daily => (
    description => <<'',
Returns the top 20 trending topics for each hour in a given day.

    path     => 'trends/daily',
    method   => 'GET',
    params   => [qw/date exclude/],
    required => [qw//],
    returns  => 'HashRef',
);

twitter_api_method trends_weekly => (
    description => <<'',
Returns the top 30 treding topics for each day in a given week.

    path     => 'trends/weekly',
    method   => 'GET',
    params   => [qw/date exclude/],
    required => [qw//],
    returns  => 'HashRef',
);

1;

__END__

=head1 NAME

Net::Twitter::Lite::API - A definition of the Twitter Search API

=head1 SYNOPSIS

    use aliased 'Net::Twitter::Lite::API::Search';

    my $api_def = API->definition;

=head1 DESCRIPTION

B<Net::Twitter::Lite::API::Search> provides a perl data structure describing
the Twitter Search API.  It is used by the Net::Twitter::Lite distribution to
dynamically build methods, documentation, and tests.

=head1 METHODS

=over 4

=item base_url

Returns the base URL for the Twitter Search API.

=item definition

Returns a perl data structure describing the Twitter Search API.  See
L<Net::Twitter::Lite::API> for documentation on the data structure format.

=back

=head1 SEE ALSO

=over 4

=item L<Net::Twitter::Lite>

Net::Twitter::Lite::API was written for the use of this module and its distribution.

=item L<http://apiwiki.twitter.com/Search+API+Documentation>

The Twitter Search API documentation

=back

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

Copyright (c) 2009 Marc Mims

The Twitter API itself, and the description text used in this module is:

Copyright (c) 2009 Twitter

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
