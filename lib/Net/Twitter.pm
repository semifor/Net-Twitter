package Net::Twitter;
use 5.8.1;
use Moose;
use Carp;
use JSON::Any qw/XS DWIW JSON/;
use URI::Escape;
use Net::Twitter::Error;

# use *all* digits for fBSD ports
our $VERSION = '2.99000_01';

$VERSION = eval $VERSION; # numify for warning-free dev releases

has useragent_class => ( isa => 'Str', is => 'ro', default => 'LWP::UserAgent' );
has username        => ( isa => 'Str', is => 'rw', predicate => 'has_username' );
has password        => ( isa => 'Str', is => 'rw' );
has useragent       => ( isa => 'Str', is => 'ro', default => __PACKAGE__ . "/$VERSION" );
has source          => ( isa => 'Str', is => 'ro', default => 'twitterpm' );
has ua              => ( isa => 'Object', is => 'rw' );
has clientname      => ( isa => 'Str', is => 'ro', default => 'Perl Net::Twitter' );
has clientver       => ( isa => 'Str', is => 'ro', default => $VERSION );
has clienturl       => ( isa => 'Str', is => 'ro', default => 'http://search.cpan.org/dist/Net-Twitter/' );

sub import {
    my ($class, @args) = @_;

    @args = 'Legacy' unless @args;

    if ( $args[0] eq 'Legacy' ) {
        unshift @args, 'WrapError', map "API::$_", qw/REST Search TwitterVision/;
    }

    with "Net::Twitter::$_" for @args;

    $class->meta->make_immutable;
}

sub BUILD {
    my $self = shift;

    eval "use " . $self->useragent_class;
    croak $@ if $@;

    $self->ua($self->useragent_class->new);
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

sub from_json {
    my ($self, $json) = @_;

    return eval { JSON::Any->from_json($json) };
}

sub parse_result {
    my ($self, $res) = @_;

    my $obj = $self->from_json($res->content);

    # Twitter sometimes returns an error with status code 200
    if ( $obj && ref $obj eq 'HASH' && exists $obj->{error} ) {
        die Net::Twitter::Error->new(twitter_error => $obj, http_response => $res);
    }

    return $obj if $res->is_success && $obj;

    my $error = Net::Twitter::Error->new(http_response => $res);
    $error->twitter_error($obj) if $obj;

    die $error;
}

no Moose;

1;
