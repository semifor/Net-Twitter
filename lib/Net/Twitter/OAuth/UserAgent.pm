package Net::Twitter::OAuth::UserAgent;
use Moose;

use namespace::autoclean;

extends qw/LWP::UserAgent Moose::Object/;

has oauth => ( isa => 'Net::OAuth::Simple', is => 'ro', required => 1,
               handles => [qw/make_restricted_request/] );

sub new {
    my $class = shift;

    my $new = $class->SUPER::new;

    return $class->meta->new_object(
        __INSTANCE__ => $new,
        oauth => @_,
    );
}

override get => sub {
    my ($self, $url) = @_;

    $self->make_restricted_request($url, 'GET');
};

override post => sub  {
    my ($self, $url, $args) = @_;

    # OAuth doesn't support 'source' prarameter anymore
    delete $args->{source};

    # Net::OAuth::Simple doesn't really do POST encoding but seems to work
    $self->make_restricted_request($url, 'POST', %$args);
};

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
