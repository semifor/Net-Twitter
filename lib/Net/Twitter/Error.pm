package Net::Twitter::Error;
use Moose;

use overload '""' => \&stringify;

has twitter_error   => ( isa => 'HashRef', is => 'rw', predicate => 'has_twitter_error' );
has http_response   => ( isa => 'HTTP::Response', is => 'rw', required => 1, handles => [qw/code message/] );

sub stringify {
    my $self = shift;

    # We MUST stringyfy to something that evaluates to true, or testing $@ will fail!
    $self->has_twitter_error && $self->twitter_error->{error}
        || $self->message
        || $self->code
        || -1;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Twitter::Error - A Net::Twitter::Lite exception object

=head1 SYNOPSIS

    my $nt = Net::Twitter->new(username => $username, password => $password);

    my $followers = eval { $nt->followers };
    if ( $@ ) {
        warn "$@\n";
    }

=head1 DESCRIPTION

B<Net::Twitter::Error> encapsulates the C<HTTP::Response> and Twitter
error HASH (if any) resulting from a failed API call.

=head1 METHODS

=over 4

=item new(http_response => $res)

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

=item stringify

Returns the error element of the Twitter error HASH, if one exists.  Otherwise,
it returns the HTTP message.  =back

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
