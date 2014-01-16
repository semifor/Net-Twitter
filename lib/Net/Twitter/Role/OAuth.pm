package Net::Twitter::Role::OAuth;

use Moose::Role;
use HTTP::Request::Common;
use Carp::Clan qw/^(?:Net::Twitter|Moose|Class::MOP)/;
use URI;
use Digest::SHA;
use List::Util qw/first/;

requires qw/_add_authorization_header ua/;

use namespace::autoclean;

use Net::OAuth;
$Net::OAuth::PROTOCOL_VERSION = Net::OAuth::PROTOCOL_VERSION_1_0A;

# flatten oauth_urls with defaults
around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $args = $class->$orig(@_);
    my $oauth_urls = delete $args->{oauth_urls} || {
        request_token_url  => "https://api.twitter.com/oauth/request_token",
        authentication_url => "https://api.twitter.com/oauth/authenticate",
        authorization_url  => "https://api.twitter.com/oauth/authorize",
        access_token_url   => "https://api.twitter.com/oauth/access_token",
        xauth_url          => "https://api.twitter.com/oauth/access_token",
    };

    return { %$oauth_urls, %$args };
};

has consumer_key    => ( isa => 'Str', is => 'ro', required => 1 );
has consumer_secret => ( isa => 'Str', is => 'ro', required => 1 );

# url attributes
for my $attribute ( qw/authentication_url authorization_url request_token_url access_token_url xauth_url/ ) {
    has $attribute => (
        isa    => 'Str', is => 'rw', required => 1,
        # inflate urls to URI objects when read
        reader => { $attribute => sub { URI->new(shift->{$attribute}) } },
    );
}

# token attributes
for my $attribute ( qw/access_token access_token_secret request_token request_token_secret/ ) {
    has $attribute => ( isa => 'Str', is => 'rw',
                        clearer   => "clear_$attribute",
                        predicate => "has_$attribute",
    );
}

# simple check to see if we have access tokens; does not check to see if they are valid
sub authorized {
    my $self = shift;

    return defined $self->has_access_token && $self->has_access_token_secret;
}

# get the authorization or authentication url
sub _get_auth_url {
    my ($self, $which_url, %params ) = @_;

    my $callback = delete $params{callback} || 'oob';
    $self->_request_request_token(callback => $callback);

    my $uri = $self->$which_url;
    $uri->query_form(oauth_token => $self->request_token, %params);
    return $uri;
}

# get the authentication URL from Twitter
sub get_authentication_url { return shift->_get_auth_url(authentication_url => @_) }

# get the authorization URL from Twitter
sub get_authorization_url { return shift->_get_auth_url(authorization_url => @_) }

# common portion of all oauth requests
sub _make_oauth_request {
    my ($self, $type, %params) = @_;

    my $class = $type =~ s/^\+// ? $type : Net::OAuth->request($type);
    my $request = $class->new(
        version          => '1.0',
        consumer_key     => $self->{consumer_key},
        consumer_secret  => $self->{consumer_secret},
        request_method   => 'GET',
        signature_method => 'HMAC-SHA1',
        timestamp        => time,
        nonce            => Digest::SHA::sha1_base64(time . $$ . rand),
        %params,
    );

    $request->sign;

    return $request;
}

# called by get_authorization_url to obtain request tokens
sub _request_request_token {
    my ($self, %params) = @_;

    my $uri = $self->request_token_url;
    my $request = $self->_make_oauth_request(
        'request token',
        request_url => $uri,
        %params,
    );

    my $msg = HTTP::Request->new(GET => $uri);
    $msg->header(authorization => $request->to_authorization_header);

    my $res = $self->_send_request($msg);
    croak "GET $uri failed: ".$res->status_line
        unless $res->is_success;

    # reuse $uri to extract parameters from the response content
    $uri->query($res->content);
    my %res_param = $uri->query_form;

    $self->request_token($res_param{oauth_token});
    $self->request_token_secret($res_param{oauth_token_secret});
}

# exchange request tokens for access tokens; call with (verifier => $verifier)
sub request_access_token {
    my ($self, %params ) = @_;

    my $uri = $self->access_token_url;
    my $request = $self->_make_oauth_request(
        'access token',
        request_url => $uri,
        token       => $self->request_token,
        token_secret => $self->request_token_secret,
        %params, # verifier => $verifier
    );

    my $msg = HTTP::Request->new(GET => $uri);
    $msg->header(authorization => $request->to_authorization_header);

    my $res = $self->_send_request($msg);
    croak "GET $uri failed: ".$res->status_line
        unless $res->is_success;

    # discard request tokens, they're no longer valid
    $self->clear_request_token;
    $self->clear_request_token_secret;

    # reuse $uri to extract parameters from content
    $uri->query($res->content);
    my %res_param = $uri->query_form;

    return (
        $self->access_token($res_param{oauth_token}),
        $self->access_token_secret($res_param{oauth_token_secret}),
        $res_param{user_id},
        $res_param{screen_name},
    );
}

around _prepare_request => sub {
    my $orig = shift;
    my ($self, $http_method, $uri, $args, $authenticate) = @_;

    delete $args->{source};
    $orig->(@_);
};

override _add_authorization_header => sub {
    my ( $self, $msg, $args ) = @_;

    return unless $self->authorized;

    my $is_multipart = grep { ref } %$args;

    local $Net::OAuth::SKIP_UTF8_DOUBLE_ENCODE_CHECK = 1;

    my $uri = $msg->uri->clone;
    $uri->query(undef);

    my $request = $self->_make_oauth_request(
        'protected resource',
        request_url    => $uri,
        request_method => $msg->method,
        token          => $self->access_token,
        token_secret   => $self->access_token_secret,
        extra_params   => $is_multipart ? {} : $args,
    );

    $msg->header(authorization => $request->to_authorization_header);
};

sub xauth {
    my ( $self, $username, $password ) = @_;

    my @args = (
        x_auth_username => $username,
        x_auth_password => $password,
        x_auth_mode     => 'client_auth',
    );

    my $uri = $self->xauth_url;
    my $request = $self->_make_oauth_request(
        'XauthAccessToken',
        request_url    => $uri,
        request_method => 'POST',
        @args,
    );

    my $res = $self->ua->request(
        POST $uri, \@args, Authorization => $request->to_authorization_header);
    die "POST $uri failed: ".$res->status_line
        unless $res->is_success;

    # reuse $uri to extract parameters from content
    $uri->query($res->content);
    my %res_param = $uri->query_form;

    return (
        $self->access_token($res_param{oauth_token}),
        $self->access_token_secret($res_param{oauth_token_secret}),
        $res_param{user_id},
        $res_param{screen_name},
    );
}

# shortcuts defined in early releases
# DEPRECATED

sub oauth_token {
    my($self, @tokens) = @_;

    carp "DEPRECATED: use access_token and access_token_secret instead";
    $self->access_token($tokens[0]);
    $self->access_token_secret($tokens[1]);
    return @tokens;
}

sub is_authorized {
    carp "DEPRECATED: use authorized instead";
    shift->authorized(@_)
}

sub oauth_authorization_url {
    carp "DEPRECATED: use get_authorization_url instead";
    shift->get_authorization_url(@_)
}

sub oauth {
    carp "DEPRECATED: call this method on Net::Twitter itself, rather than through the oauth accessor";
    shift
}

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Net::Twitter::Role::OAuth - Net::Twitter role that provides OAuth instead of Basic Authentication

=head1 SYNOPSIS

  use Net::Twitter;

  my $nt = Net::Twitter->new(
      traits          => ['API::RESTv1_1', 'OAuth'],
      consumer_key    => "YOUR-CONSUMER-KEY",
      consumer_secret => "YOUR-CONSUMER-SECRET",
  );

  # Do some Authentication work. See EXAMPLES

  my $tweets = $nt->friends_timeline;
  my $res    = $nt->update({ status => "I CAN HAZ OAUTH!" });

=head1 DESCRIPTION

Net::Twitter::Role::OAuth is a Net::Twitter role that provides OAuth
authentication instead of the default Basic Authentication.

Note that this client only works with APIs that are compatible to OAuth authentication.

=head1 IMPORTANT

Beginning with version 3.02, it is necessary for web applications to pass the
C<callback> parameter to C<get_authorization_url>.  In the absence of a
callback parameter, when the user authorizes the application a PIN number is
displayed rather than redirecting the user back to your site.

=head1 EXAMPLES

See the C<examples> directory in this distribution for working examples of both
desktop and web applications.

Here's how to authorize users as a desktop app mode:

  use Net::Twitter;

  my $nt = Net::Twitter->new(
      traits          => ['API::RESTv1_1', 'OAuth'],
      consumer_key    => "YOUR-CONSUMER-KEY",
      consumer_secret => "YOUR-CONSUMER-SECRET",
  );

  # You'll save the token and secret in cookie, config file or session database
  my($access_token, $access_token_secret) = restore_tokens();
  if ($access_token && $access_token_secret) {
      $nt->access_token($access_token);
      $nt->access_token_secret($access_token_secret);
  }

  unless ( $nt->authorized ) {
      # The client is not yet authorized: Do it now
      print "Authorize this app at ", $nt->get_authorization_url, " and enter the PIN#\n";

      my $pin = <STDIN>; # wait for input
      chomp $pin;

      my($access_token, $access_token_secret, $user_id, $screen_name) = $nt->request_access_token(verifier => $pin);
      save_tokens($access_token, $access_token_secret); # if necessary
  }

  # Everything's ready

In a web application mode, you need to save the oauth_token and
oauth_token_secret somewhere when you redirect the user to the OAuth
authorization URL.

  sub twitter_authorize : Local {
      my($self, $c) = @_;

      my $nt = Net::Twitter->new(traits => [qw/API::RESTv1_1 OAuth/], %param);
      my $url = $nt->get_authorization_url(callback => $callbackurl);

      $c->response->cookies->{oauth} = {
          value => {
              token => $nt->request_token,
              token_secret => $nt->request_token_secret,
          },
      };

      $c->response->redirect($url);
  }

And when the user returns back, you'll reset those request token and
secret to upgrade the request token to access token.

  sub twitter_auth_callback : Local {
      my($self, $c) = @_;

      my %cookie = $c->request->cookies->{oauth}->value;
      my $verifier = $c->req->params->{oauth_verifier};

      my $nt = Net::Twitter->new(traits => [qw/API::RESTv1_1 OAuth/], %param);
      $nt->request_token($cookie{token});
      $nt->request_token_secret($cookie{token_secret});

      my($access_token, $access_token_secret, $user_id, $screen_name)
          = $nt->request_access_token(verifier => $verifier);

      # Save $access_token and $access_token_secret in the database associated with $c->user
  }

Later on, you can retrieve and reset those access token and secret
before calling any Twitter API methods.

  sub make_tweet : Local {
      my($self, $c) = @_;

      my($access_token, $access_token_secret) = ...;

      my $nt = Net::Twitter->new(traits => [qw/API::RESTv1_1 OAuth/], %param);
      $nt->access_token($access_token);
      $nt->access_token_secret($access_token_secret);

      # Now you can call any Net::Twitter API methods on $nt
      my $status = $c->req->param('status');
      my $res = $nt->update({ status => $status });
  }

=head1 METHODS

=over 4

=item authorized

Whether the client has the necessary credentials to be authorized.

Note that the credentials may be wrong and so the request may fail.

=item request_access_token(verifier => $verifier)

Request the access token, access token secret, user id and screen name for
this user. You must pass the PIN# (for desktop applications) or the
C<oauth_verifier> value, provided as a parameter to the oauth callback
(for web applications) as C<$verifier>.

The user must have authorized this app at the url given by C<get_authorization_url> first.

Returns the access_token, access_token_secret, user_id, and screen_name in a
list.  Also sets them internally so that after calling this method, you can
immediately call API methods requiring authentication.

=item xauth($username, $password)

Exchanges the C<$username> and C<$password> for access tokens.  This method has
the same return value as C<request_access_token>: access_token, access_token_secret,
user_id, and screen_name in a list. Also, like C<request_access_token>, it sets
the access_token and access_secret, internally, so you can immediately call API
methods requiring authentication.

=item get_authorization_url(callback => $callback_url)

Get the URL used to authorize the user.  Returns a C<URI> object.  For web
applications, pass your applications callback URL as the C<callback> parameter.
No arguments are required for desktop applications (C<callback> defaults to
C<oob>, out-of-band).

=item get_authentication_url(callback => $callback_url)

Get the URL used to authenticate the user with "Sign in with Twitter"
authentication flow.  Returns a C<URI> object.  For web applications, pass your
applications callback URL as the C<callback> parameter.  No arguments are
required for desktop applications (C<callback> defaults to C<oob>, out-of-band).

=item access_token

Get or set the access token.

=item access_token_secret

Get or set the access token secret.

=item request_token

Get or set the request token.

=item request_token_secret

Get or set the request token secret.

=back

=head1 DEPRECATED METHODS

=over 4

=item oauth

Prior versions used Net::OAuth::Simple.  This method provided access to the
contained Net::OAuth::Simple object. Beginning with Net::Twitter 3.00, the
OAuth methods were delegated to Net::OAuth::Simple.  They have since made first
class methods.  Net::Simple::OAuth is no longer used.  A warning will be
displayed when accessing OAuth methods via the <oauth> method.  The C<oauth>
method will be removed in a future release.

=item is_authorized

Use C<authorized> instead.

=item oauth_authorization_url

Use C<get_authorization_url> instead.

=item oauth_token

   $nt->oauth_token($access_token, $access_token_secret);

Use C<access_token> and C<access_token_seccret> instead:

   $nt->access_token($access_token);
   $nt->access_token_secret($access_token_secret);

=back

=head1 ACKNOWLEDGEMENTS

This module was originally authored by Tatsuhiko Miyagawa as
C<Net::Twitter::OAuth>, a subclass of the C<Net::Twitter> 2.x. It was
refactored into a Moose Role for use in C<Net::Twitter> 3.0 and above by Marc
Mims.  Many thanks to Tatsuhiko for the original work on both code and
documentation.

=head1 AUTHORS

Marc Mims E<lt>marc@questright.comE<gt>

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::Twitter>, L<Net::Twitter::OAuth::Simple>, L<Net::OAuth::Simple>

=cut

