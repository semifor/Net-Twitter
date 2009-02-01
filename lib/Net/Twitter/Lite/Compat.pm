package Net::Twitter::Lite::Compat;
use Moose;
use aliased 'Net::Twitter::Lite::API::REST';

extends 'Net::Twitter::Lite';

has _response       => ( isa => 'HTTP::Response', is => 'rw' );

sub get_error { shift->_response->content }
sub http_code { shift->_response->code }
sub http_message { shift->_response->message }

my $wrapper = sub {
    my $next = shift;
    my $self = shift;

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
