package Net::Identica;
use Moose;

# use *all* digits for fBSD ports
our $VERSION = '3.15000';
$VERSION     = eval $VERSION; # numify for warning-free dev releases

extends 'Net::Twitter::Core';
with map "Net::Twitter::Role::$_", qw/Legacy/;

has '+apiurl'    => ( default => 'http://identi.ca/api' );
has '+apirealm'  => ( default => 'Laconica API'         );

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Identica - A perl interface to the Identi.ca Twitter Compatible API

=head1 SYNOPSIS

  use Net::Identica;

  $nt = Net::Identica->new(username => $user, password => $passwd);

  $nt->update('Hello, Identica friends!');

=head1 DEPRECATED

This module is a backwards compatibility wrapper for applications that used
L<Net::Identica> packaged with C<Net::Twitter> versions 2.12 and earlier.
Instead, use L<Net::Twitter> with the C<identica> option to gain all of the new
features and functionality (OAuth, Search, exceptions on error, etc.).

  use Net::Twitter;

  # A simple, backwards compatible replacement for Net::Identica
  my $identica = Net::Twitter->new(
      legacy   => 1,
      identica => 1,
      username => $username,
      password => $password,
  );

  # A more complex object with OAuth and some optional traits
  my $identica = Net::Twitter->new(
      traits => [qw/API::REST API::Search OAuth InflateObjects/],
      identica            => 1,
      consumer_key        => $consumer_key,
      consumer_secret     => $consumer_secret,
      access_token        => $token,
      access_token_secret => $token_secret,
  );

=head1 DESCRIPTION

The micro-blogging service L<http://identi.ca> provides a Twitter compatible API.
This module simply creates an instance of C<Net::Twitter> with the C<identica>
option set.

See L<Net::Twitter> for full documentation.

=head1 METHODS

=over 4

=item new

Creates a C<Net::Twitter> object by call L<Net::Twitter/new> with the
C<identica> option preset.

=back

=head1 SEE ALSO

=over 4

=item L<Net::Twitter>

Full documentation.

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
