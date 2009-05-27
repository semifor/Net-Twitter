package Net::Twitter::Role::API::Search;

use Moose::Role;
use Net::Twitter::API;

has searchapiurl   => ( isa => 'Str', is => 'rw', default => 'http://search.twitter.com' );

base_url 'searchapiurl';

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
Returns the top ten queries that are currently trending on Twitter.  The
response includes the time of the request, the name of each trending topic, and
the url to the Twitter Search results page for that topic.

    path     => 'trends',
    method   => 'GET',
    params   => [qw//],
    required => [qw//],
    returns  => 'ArrayRef[Query]',
);

twitter_api_method trends_current => (
    description => <<'',
Returns the current top ten trending topics on Twitter.  The response includes
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
Returns the top 30 trending topics for each day in a given week.

    path     => 'trends/weekly',
    method   => 'GET',
    params   => [qw/date exclude/],
    required => [qw//],
    returns  => 'HashRef',
);

1;

__END__

=head1 NAME

Net::Twitter::Role::API::Search - A definition of the Twitter Search API as a Moose role

=head1 SYNOPSIS

  package My::Twitter;
  use Moose;
  with 'Net::Twitter::API::Search';

=head1 DESCRIPTION

B<Net::Twitter::Role::API::Search> provides definitions for all the Twitter Search API
methods.  Applying this role to any class provides methods for all of the
Twitter Search API methods.


=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

Copyright (c) 2009 Marc Mims

The Twitter API itself, and the description text used in this module is:

Copyright (c) 2009 Twitter

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
