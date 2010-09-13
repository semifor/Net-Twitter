package Net::Twitter::Role::API::TwitterVision;
use Moose::Role;

requires qw/credentials/;

use Net::Twitter::API;

has tvurl         => ( isa => 'Str',  is => 'ro', default => 'http://twittervision.com' );
has tvhost        => ( isa => 'Str',  is => 'ro', default => 'twittervision.com:80'     );
has tvrealm       => ( isa => 'Str',  is => 'ro', default => 'Web Password'             );

requires qw/ua username password/;

base_url     'tvurl';
authenticate 1;

twitter_api_method current_status => (
    description => <<'',
Get the current location and status of a user.

    path     => 'user/current_status/id',
    method   => 'GET',
    params   => [qw/id callback/],
    required => [qw/id/],
    returns  => 'HashRef',
);

twitter_api_method update_twittervision => (
    description => <<'',
Updates the location for the authenticated user.

    path     => 'user/update_location',
    method   => 'POST',
    params   => [qw/location/],
    required => [qw/location/],
    returns  => 'HashRef',
);

1;

__END__

=head1 NAME

Net::Twitter::Role::API::TwitterVision - A definition of the TwitterVision API as a Moose role

=head1 SYNOPSIS

  package My::Twitter;
  use Moose;
  with 'Net::Twitter::API::TwitterVision';

=head1 DESCRIPTION

B<Net::Twitter::Role::API::TwitterVision> provides definitions for all the TwitterVision API
methods.  Applying this role to any class provides methods for all of the
TwitterVision API methods.

=head1 METHODS

=over 4

=item new

Adds the following options to L<Net::Twitter/new>:

=over 4

=item tvurl

A string containing the base URL for the TwitterVision API.  Defaults to "http://twittervision.com".

=item tvhost

A string containing the TwitterVision API host.  Defaults to "twittervision.com:80".

=item tvrealm

A string containing the TwitterVision Basic Authentication Realm name.  Defaults to "Web Password".

=back

=back

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
