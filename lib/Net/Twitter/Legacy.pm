package Net::Twitter::Legacy;
use Moose::Role;

use namespace::autoclean;

with "Net::Twitter::$_" for qw/
    API::REST
    API::Search
    API::TwitterVision
    WrapError
/;

has arrayref_on_error => ( isa => 'Bool', is => 'rw', default => 0, trigger => \&_set_error_return_val );

sub _set_error_return_val {
    my $self = shift;

    $self->_error_return_val($self->arrayref_on_error ? [] : undef);
}

around BUILDARGS => sub {
    my $next    = shift;
    my $class   = shift;
    my %options = @_;

    if ( delete $options{identica} ) {
        %options = (
            apiurl => 'http://identi.ca/api',
            apihost => 'identi.ca:80',
            apirealm => 'Laconica API',
            %options,
        );
    }

    return $next->($class, %options);
};

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

Net::Twitter - A Net::Twitter legacy compatibility layer

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
