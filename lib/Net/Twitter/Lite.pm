package Net::Twitter::Lite;
use 5.008;
use Moose;
use Carp;
use JSON::Any qw/XS DWIW JSON/;
use URI::Escape;
use aliased 'Net::Twitter::Lite::API::REST' => 'API';

# use *all* digits for fBSD ports
our $VERSION = '0.00000_01';

$VERSION = eval $VERSION; # numify for warning-free dev releases

has useragent_class => ( isa => 'Str', is => 'ro', default => 'LWP::UserAgent' );
has username        => ( isa => 'Str', is => 'rw' );
has password        => ( isa => 'Str', is => 'rw' );
has useragent       => ( isa => 'Str', is => 'ro', default => __PACKAGE__ . "/$VERSION" );
has source          => ( isa => 'Str', is => 'ro', default => 'twitterpm' );
has apiurl          => ( isa => 'Str', is => 'ro', default => API->base_url );
has apihost         => ( isa => 'Str', is => 'ro', default => 'twitter.com:80' );
has apirealm        => ( isa => 'Str', is => 'ro', default => 'Twitter API' );
has _ua             => ( isa => 'Object', is => 'rw' );

use Exception::Class (
    TwitterException => {
        description => 'Twitter API error',
        fields      => [qw/http_response twitter_error/ ],
    },
    HttpException   => {
        description => 'HTTP or network error',
        fields      => [qw/http_response/],
    },
);

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

my $post_request = sub {
    my ($ua, $uri, $args) = @_;
    return $ua->post($uri, $args);
};

my $get_request = sub {
    my ($ua, $uri, $args) = @_;
    $uri->query_form($args);
    return $ua->get($uri);
};

my $with_url_arg = sub {
    my ($path, $args) = @_;

    if ( defined(my $id = delete $args->{id}) ) {
        $path .= uri_escape($id);
    }
    else {
        chop($path);
    }
    return $path;
};

my $method_defs = API->method_definitions;
while ( my ($method, $def) = each %$method_defs ) {
    my ($arg_names, $path) = @{$def}{qw/required path/};
    my $request = $def->{method} eq 'POST' ? $post_request : $get_request;

    my $modify_path = $path =~ s,/id$,/, ? $with_url_arg : sub { $_[0] };

    my $code = sub {
        my $self = shift;

        my $args = {};
        if ( ref $_[0] ) {
            UNIVERSAL::isa($_[0], 'HASH') && @_ == 1 || croak "$method expected a single HASH ref argument";
            $args = { %{shift()} }; # copy callers args since we may add ->{source}
        }
        elsif ( @_ ) {
            @_ == @$arg_names || croak "$method expected @{[ scalar @$arg_names ]} args";
            @{$args}{@$arg_names} = @_;
        }
        $args->{source} ||= $self->source if $method eq 'update';

        my $local_path = $modify_path->($path, $args);
        my $uri = URI->new($self->apiurl . "/$local_path.json");
        my $res = $self->_response($request->($self->_ua, $uri, $args));
        my $obj = eval { JSON::Any->from_json($res->content) };

        return $obj if $res->is_success && $obj;
        TwitterException->throw(
            error         => $obj->{error},
            http_response => $res,
            twitter_error => $obj
        ) if $obj;
        HttpException->throw(
            error         => $res->message,
            http_response => $res,
        );
    };

    __PACKAGE__->meta->add_method($_, $code) for ( $method, @{$def->{aliases} || []});
}

__PACKAGE__->meta->make_immutable;

1;
