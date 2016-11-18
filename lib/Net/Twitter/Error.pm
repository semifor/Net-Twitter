package Net::Twitter::Error;

use Moose;
use Try::Tiny;
use Devel::StackTrace;

use overload (
    # We can't use 'error' directly, because overloads are called with three
    # arguments ($self, undef, '') resulting in an error:
    # Cannot assign a value to a read-only accessor
    '""'     => sub { shift->error },

    fallback => 1,
);

has http_response => (
    isa      => 'HTTP::Response',
    is       => 'ro',
    required => 1,
    handles  => [qw/code message/],
);

has twitter_error => (
    is        => 'ro',
    predicate => 'has_twitter_error',
);

has stack_trace => (
    is       => 'ro',
    init_arg => undef,
    builder  => '_build_stack_trace',
    handles => {
        stack_frame => 'frame',
    },
);

sub _build_stack_trace {
    my $seen;
    my $this_sub = (caller 0)[3];
    Devel::StackTrace->new(frame_filter => sub {
        my $caller = shift->{caller};
        my $in_nt = $caller->[0] =~ /^Net::Twitter::/ || $caller->[3] eq $this_sub;
        ($seen ||= $in_nt) && !$in_nt || 0;
    });
}

has error => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_error',
);

sub _build_error {
    my $self = shift;

    my $error = $self->twitter_error_text || $self->http_response->status_line;
    my ($location) = $self->stack_frame(0)->as_string =~ /( at .*)/;
    return $error . ($location || '');
}

sub twitter_error_text {
    my $self = shift;
    # Twitter does not return a consistent error structure, so we have to
    # try each known (or guessed) variant to find a suitable message...

    return '' unless $self->has_twitter_error;
    my $e = $self->twitter_error;

    return ref $e eq 'HASH' && (
        # the newest variant: array of errors
        exists $e->{errors}
            && ref $e->{errors} eq 'ARRAY'
            && exists $e->{errors}[0]
            && ref $e->{errors}[0] eq 'HASH'
            && exists $e->{errors}[0]{message}
            && $e->{errors}[0]{message}

        # it's single error variant
        || exists $e->{error}
            && ref $e->{error} eq 'HASH'
            && exists $e->{error}{message}
            && $e->{error}{message}

        # the original error structure (still applies to some endpoints)
        || exists $e->{error} && $e->{error}

        # or maybe it's not that deep (documentation would be helpful, here,
        # Twitter!)
        || exists $e->{message} && $e->{message}
    ) || ''; # punt
}

sub twitter_error_code {
    my $self = shift;

    return $self->has_twitter_error
        && exists $self->twitter_error->{errors}
        && exists $self->twitter_error->{errors}[0]
        && exists $self->twitter_error->{errors}[0]{code}
        && $self->twitter_error->{errors}[0]{code}
        || 0;
}

__PACKAGE__->meta->make_immutable;

no Moose;

1;

__END__

=head1 NAME

Net::Twitter::Error - A Net::Twitter exception object

=head1 SYNOPSIS

    use Scalar::Util qw/blessed/;
    use Try::Tiny;

    my $nt = Net::Twitter->new(@options);

    my $followers = try {
        $nt->followers;
    }
    catch {
        die $_ unless blessed($_) && $_->isa('Net::Twitter::Error');

        warn "HTTP Response Code: ", $_->code, "\n",
             "HTTP Message......: ", $_->message, "\n",
             "Twitter error.....: ", $_->error, "\n",
             "Stack Trace.......: ", $_->stack_trace->as_string, "\n";
    };

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
Otherwise, it returns the string "[unknown]". Includes a stack trace.

=item twitter_error_text

Returns the C<error> value from the C<twitter_error> HASH ref if there is one.
Otherwise, returns an empty string

=item twitter_error_code

Returns the first numeric twitter error code from the JSON response body, if
there is one. Otherwise, it returns 0 so the result should always be safe use
in a numeric test.

See L<Twitter Error Codes|https://dev.twitter.com/docs/error-codes-responses>
for a list of defined error codes.

=item stack_trace

Returns a L<Devel::StackTrace> object.

=item stack_frame($i)

Returns the C<$i>th stack frame as a L<Devel::StackTrace::Frame> object.

=back

=head1 SEE ALSO

=over 4

=item L<Net::Twitter>

=back

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

Copyright (c) 2016 Marc Mims

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
