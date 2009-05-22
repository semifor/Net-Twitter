package Net::Twitter::WrapError;
use Moose::Role;

use namespace::autoclean;

has _error  => (
    isa       => 'Net::Twitter::Error',
    is        => 'rw',
    clearer   => '_clear_error',
    predicate => 'has_error',
);

has _error_return_val => ( isa => 'Maybe[ArrayRef]', is => 'rw', default => undef );

sub http_message {
    my $self = shift;

    return unless $self->has_error;
    return $self->_error->message;
}

sub http_code {
    my $self = shift;

    return unless $self->has_error;
    return $self->_error->code;
}

sub get_error {
    my $self = shift;

    return unless $self->has_error;

    return $self->_error->has_twitter_error
        ? $self->_error->twitter_error
        : {
            request => undef,
            error   => "TWITTER RETURNED ERROR MESSAGE BUT PARSING OF JSON RESPONSE FAILED - "
                       . $self->_error->message
          }; 
}

around _parse_result => sub {
    my $next = shift;
    my $self = shift;

    $self->_clear_error;

    my $r = eval { $next->($self, @_) };
    if ( $@ ) {
        die $@ unless UNIVERSAL::isa($@, 'Net::Twitter::Error');

        $self->_error($@);
        return $self->_error_return_val;
    }

    return $r;
};

1;

__END__

=head1 NAME

Net::Twitter::WrapError - Wraps Net::Twitter exceptions

=head1 SYNOPSIS

    use Net::Twitter;

    my $nt = Net::Twitter->new(username => $username, password => $password);

    my $followers = $nt->followers;
    if ( !followers ) {
        warn $nt->http_message;
    }

=head1 DESCRIPTION

This module provides a B<Net::Twitter> compatibility layer for
Net::Twitter.  Net::Twitter::Base throws exceptions for Twitter API and
network errors.  This module catches those errors returning C<undef> to the
caller, instead.  It provides L</"get_error">, L</"http_code"> and
L</"http_message">, like Net::Twitter, for accessing that error information.

This module is provided to make it easy to test or migrate applications to
Net::Twitter::REST.

This module does not provide full compatibility with Net::Twitter.  It does not,
for example, provided C<update_twittervision> or the Twitter Search API
methods. (See L<Net::Twitter::Search> for Net::Twitter::Lite's answer to
answer to the latter.

=head1 METHODS

=over 4

=item new

This method takes the same parameters as L<Net::Twitter::Base/new>.

=item get_error

Returns the HTTP response content for the most recent API method call if it ended in error.

=item http_code

Returns the HTTP response code the most recent API method call if it ended in error.

=item http_message

Returns the HTTP message for the most recent API method call if it ended in error.

=back

=head1 SEE ALSO

=over 4

=item L<Net::Twitter::Base>

This is the base class for Net::Twitter::Compat.  See its documentation
for more details.

=back

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
