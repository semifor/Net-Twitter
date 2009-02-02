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

__PACKAGE__->meta->make_immutable;

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
