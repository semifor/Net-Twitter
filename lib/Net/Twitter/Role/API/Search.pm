package Net::Twitter::Role::API::Search;

use Moose::Role;
use Net::Twitter::API;
use DateTime::Format::Strptime;

with 'Net::Twitter::Role::API::Search::Trends';
excludes 'Net::Twitter::Role::API::RESTv1_1';

has searchapiurl   => ( isa => 'Str', is => 'rw', default => 'http://search.twitter.com' );

after BUILD => sub {
    my $self = shift;

    $self->{searchapiurl} =~ s/^http:/https:/ if $self->ssl;
};

base_url     'searchapiurl';
authenticate 0;

our $DATETIME_PARSER = DateTime::Format::Strptime->new(pattern => '%a, %d %b %Y %T %z');
datetime_parser $DATETIME_PARSER;

twitter_api_method search => (
    description => <<'EOT',
Returns a HASH reference with some meta-data about the query including the
C<next_page>, C<refresh_url>, and C<max_id>. The statuses are returned in
C<results>.  To iterate over the results, use something similar to:

    my $r = $nt->search($search_term);
    my $r = $nt->search({ q => $search_term, count => 10 })

    for my $status ( @{$r->{results}} ) {
        print "$status->{text}\n";
    }
EOT

    path     => 'search',
    method   => 'GET',
    params   => [qw/q geocode lang locale result_type count until since_id max_id include_entities callback/],
    required => [qw/q/],
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
