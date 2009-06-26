package Net::Twitter::Error;
use Moose;

use overload '""' => \&error;

has twitter_error   => ( isa => 'HashRef|Object', is => 'rw', predicate => 'has_twitter_error' );
has http_response   => ( isa => 'HTTP::Response', is => 'rw', required => 1, handles => [qw/code message/] );

sub error {
    my $self = shift;

    # We MUST stringyfy to something that evaluates to true, or testing $@ will fail!
    $self->has_twitter_error && $self->twitter_error->{error}
        || ( $self->message . ": " . $self->code )
        || '[unknown]';
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Twitter::Error - A Net::Twitter exception object

=head1 SYNOPSIS

    my $nt = Net::Twitter->new(username => $username, password => $password);

    my $followers = eval { $nt->followers };
    if ( my $err = $@ ) {
        die $@ unless blessed $err and $err->isa('Net::Twitter::Error');

        warn "HTTP Response Code: ", $err->code, "\n",
             "HTTP Message......: ", $err->message, "\n",
             "Twitter error.....: ", $err->error, "\n";
    }

=head1 DESCRIPTION

B<Net::Twitter::Error> encapsulates the C<HTTP::Response> and Twitter
error HASH (if any) resulting from a failed API call.

=head1 METHODS

=over 4

=item new

Constructs a C<Net::Twitter::Error> object.  It accepts the following parameters:

=over 4

=item http_response

An C<HTTP::Response> object, required.

=item twitter_error

The error returned by Twitter as a HASH ref.  Optional, since some API errors do
not include a response from Twitter.  They may, instead, be the result of network
timeouts, proxy errors, or some other problem that prevents an API response.

=back

=item twitter_error

Get or set the Twitter error HASH.

=item http_response

Get or set the C<HTTP::Response> object.

=item code

Returns the HTTP response code.

=item message

Returns the HTTP response message.

=item has_twitter_error

Returns true if the object contains a Twitter error HASH.

=item error

Returns the C<error> value from the C<twitter_error> HASH ref if there is one.
Otherwise, it returns the string "[unknown]".

=back

=head1 SEE ALSO

=over 4

=item L<Net::Twitter>

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
