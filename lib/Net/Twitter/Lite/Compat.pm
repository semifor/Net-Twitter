package Net::Twitter::Lite::Compat;
use Moose;
use aliased 'Net::Twitter::Lite::API::REST';

extends 'Net::Twitter::Lite';

has _response       => ( isa => 'Maybe[HTTP::Response]', is => 'rw' );

sub get_error { shift->_response->content }
sub http_code { shift->_response->code }
sub http_message { shift->_response->message }

my $wrapper = sub {
    my $next = shift;
    my $self = shift;

    $self->_response(undef);

    my $r = eval { $next->($self, @_) };
    if ( $@ ) {
        die $@ unless ref $@;
       $self->_response($@->http_response);
       return;
    }

    return $r;
};

around $_ => $wrapper for keys %{REST->method_definitions};

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Twitter::Lite::Compat - A Net::Twitter compatibility layer

=head1 SYNOPSIS

    use aliased 'Net::Twitter::Lite::Compat' => 'Twitter';

    my $nt = Twitter->new(username => $username, password => $password);

    my $followers = $nt->followers;
    if ( !followers ) {
        warn $nt->http_message;
    }

=head1 DESCRIPTION

This module provides a B<Net::Twitter> compatibility layer for
Net::Twitter::Lite.  Net::Twitter::Lite throw exceptions for Twitter API and
network errors.  This module catches those errors returning C<undef> to the
caller, instead.  It provides L</"get_error">, L</"http_code"> and
L</"http_message">, like Net::Twitter, for accessing that error information.

This module is provided to make it easy to test or migrate applications to
Net::Twitter::Lite.

This module does not provide full compatibility with Net::Twitter.  It does not,
for example, provided C<update_twittervision> or the Twitter Search API
methods. (See L<Net::Twitter::Lite::Search> for Net::Twitter::Lite's answer to
answer to the latter.

=head1 METHODS

=over 4

=item new

This method takes the same parameters as L<Net::Twitter::Lite/new>.

=item get_error

Returns the HTTP response content for the most recent API method call if it ended in error.

=item http_code

Returns the HTTP response code the most recent API method call if it ended in error.

=item http_message

Returns the HTTP message for the most recent API method call if it ended in error.

=back

=head1 SEE ALSO

=over 4

=item L<Net::Twitter>

The original perl Twitter API interface.

=item L<Net::Twitter::Lite>

This is the base class for Net::Twitter::Lite::Compat.  See its documentation
for more details.

=back

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

Copyright (c) 2009 Marc Mims

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
