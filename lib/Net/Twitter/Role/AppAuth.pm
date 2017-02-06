package Net::Twitter::Role::AppAuth;

use Moose::Role;
use Carp::Clan   qw/^(?:Net::Twitter|Moose|Class::MOP)/;
use HTTP::Request::Common qw/POST/;
use Net::Twitter::Types;

requires qw/_add_authorization_header ua from_json/;

use namespace::autoclean;

# flatten oauth_urls with defaults
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);
    my $oauth_urls = delete $args->{oauth_urls} || {
        request_token_url    => "https://api.twitter.com/oauth2/token",
        invalidate_token_url => "https://api.twitter.com/oauth2/invalidate_token",
    };

    return { %$oauth_urls, %$args };
};

has [ qw/consumer_key consumer_secret/ ] => (
    isa      => 'Str',
    is       => 'ro',
    required => 1,
);

# url attributes
has [ qw/request_token_url invalidate_token_url/ ] => (
    isa      => 'Net::Twitter::Types::URI',
    is       => 'ro',
    required => 1,
    coerce   => 1,
);

has access_token => (
    isa       => 'Str',
    is        => 'rw',
    clearer   => "clear_access_token",
    predicate => "authorized",
);

sub _add_consumer_auth_header {
    my ( $self, $req ) = @_;

    $req->headers->authorization_basic(
        $self->consumer_key, $self->consumer_secret);
}

sub request_access_token {
    my $self = shift;

    my $req = POST($self->request_token_url,
        'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8',
        Content        => { grant_type => 'client_credentials' },
    );
    $self->_add_consumer_auth_header($req);

    my $res = $self->ua->request($req);
    croak "request_token failed: ${ \$res->code }: ${ \$res->message }"
        unless $res->is_success;

    my $r = $self->from_json($res->decoded_content);
    croak "unexpected token type: $$r{token_type}" unless $$r{token_type} eq 'bearer';

    return $self->access_token($$r{access_token});
}

sub invalidate_token {
    my $self = shift;

    croak "no access_token" unless $self->authorized;

    my $req = POST($self->invalidate_token_url,
        'Content-Type' => 'application/x-www-form-urlencoded;charset=UTF-8',
        Content        => join '=', access_token => $self->access_token,
    );
    $self->_add_consumer_auth_header($req);

    my $res = $self->ua->request($req);
    croak "invalidate_token failed: ${ \$res->code }: ${ \$res->message }"
        unless $res->is_success;

    $self->clear_access_token;
}

around _prepare_request => sub {
    my $orig = shift;
    my $self = shift;
    my ($http_method, $uri, $args, $authenticate) = @_;

    delete $args->{source};
    $self->$orig(@_);
};

override _add_authorization_header => sub {
    my ( $self, $msg ) = @_;

    return unless $self->authorized;

    $msg->header(authorization => join ' ', Bearer => $self->access_token);
};

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Net::Twitter::Role::AppAuth - OAuth2 Application Only Authentication

=head1 SYNOPSIS

  use Net::Twitter;

  my $nt = Net::Twitter->new(
      traits          => ['API::RESTv1_1', 'AppAuth'],
      consumer_key    => "YOUR-CONSUMER-KEY",
      consumer_secret => "YOUR-CONSUMER-SECRET",
  );

  $nt->request_token;

  my $tweets = $nt->user_timeline({ screen_name => 'Twitter' });

=head1 DESCRIPTION

Net::Twitter::Role::OAuth is a Net::Twitter role that provides OAuth
authentication instead of the default Basic Authentication.

Note that this client only works with APIs that are compatible to OAuth authentication.


=head1 METHODS

=over 4

=item authorized

True if the client has an access_token. This does not check the validity of the
access token, so requests may fail if it is invalid.

=item request_access_token

Request an access token. Returns the token as well as saving it in the object.

=item access_token

Get or set the access token.

=item invalidate_token

Invalidates and clears the access_token.

Note: There seems to be a Twitter bug preventing this from working---perhaps a
documentation bug. E.g., see: L<https://twittercommunity.com/t/revoke-an-access-token-programmatically-always-getting-a-403-forbidden/1902>

=back

=cut

