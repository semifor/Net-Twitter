package Net::Twitter::Lite;
use 5.008;
use Moose;
use Carp;
use JSON::Any qw/XS DWIW JSON/;
use URI::Escape;
use Net::Twitter::Lite::Error;
use aliased 'Net::Twitter::Lite::API::REST';

# use *all* digits for fBSD ports
our $VERSION = '0.00000_01';

$VERSION = eval $VERSION; # numify for warning-free dev releases

has useragent_class => ( isa => 'Str', is => 'ro', default => 'LWP::UserAgent' );
has username        => ( isa => 'Str', is => 'rw' );
has password        => ( isa => 'Str', is => 'rw' );
has useragent       => ( isa => 'Str', is => 'ro', default => __PACKAGE__ . "/$VERSION" );
has source          => ( isa => 'Str', is => 'ro', default => 'twitterpm' );
has apiurl          => ( isa => 'Str', is => 'ro', default => REST->base_url );
has apihost         => ( isa => 'Str', is => 'ro', default => 'twitter.com:80' );
has apirealm        => ( isa => 'Str', is => 'ro', default => 'Twitter API' );
has _ua             => ( isa => 'Object', is => 'rw' );

sub BUILD {
    my $self = shift;

    eval "use " . $self->useragent_class;
    croak $@ if $@;

    my $ua = $self->_ua($self->useragent_class->new);
    $ua->credentials($self->apihost, $self->apirealm, $self->username, $self->password)
        if $self->username;
}

sub credentials {
    my ($self, $username, $password) = @_;

    $self->username($username);
    $self->password($password);

    $self->_ua->credentials(@{$self}{qw/apihost apirealm username password/});

    return $self;
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
        die Net::Twitter::Lite::Error->new(twitter_error => $obj, http_response => $res);
    }

    return $obj if $res->is_success && $obj;

    my $error = Net::Twitter::Lite::Error->new(http_response => $res);
    $error->twitter_error($obj) if $obj;

    die $error;
}

no Moose;

__PACKAGE__->meta->make_immutable;

1;
