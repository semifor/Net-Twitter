package Net::Twitter::Role::Legacy;
use Moose::Role;

use namespace::autoclean;

with map "Net::Twitter::Role::$_", qw/
    API::REST
    API::Search
    API::TwitterVision
    WrapError
/;

my $set_error_return_val = sub {
    my $self = shift;

    $self->_error_return_val($self->arrayref_on_error ? [] : undef);
};

has arrayref_on_error => ( isa => 'Bool', is => 'rw', default => 0,
                           trigger => sub { shift->$set_error_return_val } );
has twittervision     => ( isa => 'Bool', is => 'rw', default => 0 );

# Legacy Net::Twitter does not make the call unless twittervision is true.
# Bug or feature?
around 'update_twittervision' => sub {
    my $next = shift;
    my $self = shift;

    return unless $self->twittervision;

    return $next->($self, @_);
};

sub clone {
    my $self = shift;

    return bless { %{$self} }, ref $self;
}

1;

__END__

=head1 NAME

Net::Twitter::Role::Legacy - A Net::Twitter legacy compatibility layer as a Moose role

=head1 SYNOPSIS

    use Net::Twitter;

    my $nt = Net::Twitter->new(
        username => $username,
        password => $password,
        traits   => [qw/Legacy/],
    );

    my $followers = $nt->followers;
    if ( !followers ) {
        warn $nt->http_message;
    }

=head1 DESCRIPTION

This module provides a B<Net::Twitter> compatibility layer for
Net::Twitter.  It pulls in the additional traits: C<API::REST>, C<API::Search>,
C<API::Identica>, and C<WrapError>.

=head1 METHODS

=over 4

=item new

This method takes the same parameters as L<Net::Twitter/new>.  In addition, it
also support the options:

=over 4

=item arrayref_on_error

When set to 1, on error, rather than returning undef, the API methods will
return an empty ARRAY ref.  Defaults to 0.

=item twittervision

When set to 1, enables the C<upade_twittervision> call.  Defaults to 0.

=back

=item clone

Creates a shallow copy of the C<Net::Twitter> object.  This was useful, in legacy
versions of C<Net::Twitter> for handling concurrent requests (for instance with
L<LWP::UserAgent::POE>).  Since errors are wrapped in the C<Net::Twitter> concurrent
requests each needed their own object.  C<clone> served that purpose.

The recommended approach for concurrent requests is to use C<Net::Twitter>'s ability
throw exceptions, now.

=back

=head1 SEE ALSO

L<Net::Twitter>

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

Copyright (c) 2009 Marc Mims

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
