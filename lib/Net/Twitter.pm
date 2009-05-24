package Net::Twitter;
use 5.8.1;
use Moose;
use Carp;
use JSON::Any qw/XS DWIW JSON/;
use URI::Escape;
use Net::Twitter::Error;

use namespace::autoclean;

with 'MooseX::Traits';

# use *all* digits for fBSD ports
our $VERSION = '2.99000_03';

$VERSION = eval $VERSION; # numify for warning-free dev releases

has useragent_class => ( isa => 'Str', is => 'ro', default => 'LWP::UserAgent' );
has useragent_args  => ( isa => 'ArrayRef', is => 'ro', default => sub { [] } );
has username        => ( isa => 'Str', is => 'rw', predicate => 'has_username' );
has password        => ( isa => 'Str', is => 'rw' );
has useragent       => ( isa => 'Str', is => 'ro', default => __PACKAGE__ . "/$VERSION (Perl)" );
has source          => ( isa => 'Str', is => 'ro', default => 'twitterpm' );
has ua              => ( isa => 'Object', is => 'rw' );
has clientname      => ( isa => 'Str', is => 'ro', default => 'Perl Net::Twitter' );
has clientver       => ( isa => 'Str', is => 'ro', default => $VERSION );
has clienturl       => ( isa => 'Str', is => 'ro', default => 'http://search.cpan.org/dist/Net-Twitter/' );
has '+_trait_namespace' => ( default => __PACKAGE__ );
has _base_url       => ( is => 'rw' ); ### keeps role composition from bitching ??

sub new {
    my $class = shift;
    
    my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    return $class->SUPER::new(%args) if caller eq 'MooseX::Traits';

    my $traits = delete $args{traits} || [qw/Legacy/];
    $class->new_with_traits(traits => $traits, %args);
}

sub BUILD {
    my $self = shift;

    eval "use " . $self->useragent_class;
    croak $@ if $@;

    $self->ua($self->useragent_class->new(@{$self->useragent_args}));
    $self->ua->agent($self->useragent);
    $self->ua->default_header('X-Twitter-Client'         => $self->clientname);
    $self->ua->default_header('X-Twitter-Client-Version' => $self->clientver);
    $self->ua->default_header('X-Twitter-Client-URL'     => $self->clienturl);
    $self->ua->env_proxy;
    $self->credentials($self->username, $self->password) if $self->has_username;
}

sub credentials {
    my ($self, $username, $password) = @_;

    $self->username($username);
    $self->password($password);

    return $self; # make it chainable
}

sub _from_json {
    my ($self, $json) = @_;

    return eval { JSON::Any->from_json($json) };
}

sub _parse_result {
    my ($self, $res) = @_;

    my $obj = $self->_from_json($res->content);

    # Twitter sometimes returns an error with status code 200
    if ( $obj && ref $obj eq 'HASH' && exists $obj->{error} ) {
        die Net::Twitter::Error->new(twitter_error => $obj, http_response => $res);
    }

    return $obj if $res->is_success && $obj;

    my $error = Net::Twitter::Error->new(http_response => $res);
    $error->twitter_error($obj) if $obj;

    die $error;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
