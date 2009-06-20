package Net::Twitter::Role::OAuth;
use Moose::Role;

requires qw/ua/;

use namespace::autoclean;

use Net::Twitter::OAuth::Simple;
use Net::Twitter::OAuth::UserAgent;

has consumer_key    => ( isa => 'Str', is => 'ro', required => 1 );
has consumer_secret => ( isa => 'Str', is => 'ro', required => 1 );
has oauth_urls      => ( isa => 'HashRef[Str]', is => 'ro', default => sub { {
        request_token_url => "http://twitter.com/oauth/request_token",
        authorization_url => "http://twitter.com/oauth/authorize",
        access_token_url  => "http://twitter.com/oauth/access_token",
    } } );

has oauth => ( isa => 'Net::Twitter::OAuth::Simple', is => 'ro', lazy_build => 1,
        handles => [qw/
            authorized
            request_access_token
            get_authorization_url
            access_token
            access_token_secret
            request_token
            request_token_secret
        /] );

sub _build_oauth {
    my $self = shift;

    my $ua = $self->ua;

    my $oauth = Net::Twitter::OAuth::Simple->new(
        useragent => $ua,
        tokens => {
            consumer_key    => $self->consumer_key,
            consumer_secret => $self->consumer_secret,
        },
        urls => $self->oauth_urls,
    );

    # override UserAgent
    $self->ua(Net::Twitter::OAuth::UserAgent->new($oauth));

    return $oauth;
}

# shortcuts defined in early releases
# DEPRECATED
sub oauth_token {
    my($self, @tokens) = @_;
    $self->{oauth}->access_token($tokens[0]);
    $self->{oauth}->access_token_secret($tokens[1]);
    return @tokens;
}

# DEPRECATED
sub is_authorized { shift->oauth->authorized(@_) }

# DEPRECATED
sub oauth_authorization_url { shift->oauth->get_authorization_url(@_) }

1;

__END__

=encoding utf-8

=for stopwords

=head1 NAME

Net::Twitter::Role::OAuth - Net::Twitter role that provides OAuth instead of Basic Authentication

=head1 SYNOPSIS

  use Net::Twitter;

  my $nt = Net::Twitter->new(
      traits          => ['API::REST', 'OAuth'],
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

=head1 EXAMPLES

Here's how to authorize users as a desktop app mode:

  use Net::Twitter;

  my $nt = Net::Twitter->new(
      traits          => ['API::REST', 'OAuth'],
      consumer_key    => "YOUR-CONSUMER-KEY",
      consumer_secret => "YOUR-CONSUMER-SECRET",
  );

  # You'll save the token and secret in cookie, config file or session database
  my($access_token, $access_token_secret) = restore_tokens();
  if ($access_token && $access_token_secret) {
      $nt->access_token($access_token);
      $nt->access_token_secret($access_token_secret);
  }

  unless ( $nt->is_authorized ) {
      # The client is not yet authorized: Do it now
      print "Authorize this app at ", $nt->get_authorization_url, " and enter the PIN#\n";

      my $pin = <STDIN>; # wait for input
      chomp $pin;

      my($access_token, $access_token_secret) = $nt->request_access_token($pin);
      save_tokens($access_token, $access_token_secret); # if necessary
  }

  # Everything's ready

In a web application mode, you need to save the oauth_token and
oauth_token_secret somewhere when you redirect the user to the OAuth
authorization URL.

  sub twitter_authorize : Local {
      my($self, $c) = @_;

      my $nt = Net::Twitter->new(traits => [qw/API::REST OAuth/], %param);
      my $url = $nt->get_authorization_url;

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

      my $nt = Net::Twitter::OAuth->new(traits => [qw/API::REST OAuth/], %param);
      $nt->request_token($cookie{token});
      $nt->request_token_secret($cookie{token_secret});

      my($access_token, $access_token_secret)
          = $nt->request_access_token;

      # Save $access_token and $access_token_secret in the database associated with $c->user
  }

Later on, you can retrieve and reset those access token and secret
before calling any Twitter API methods.

  sub make_tweet : Local {
      my($self, $c) = @_;

      my($access_token, $access_token_secret) = ...;

      my $nt = Net::Twitter::OAuth->new(traits => [qw/API::REST OAuth/], %param);
      $nt->access_token($access_token);
      $nt->access_token_secret($access_token_secret);

      # Now you can call any Net::Twitter API methods on $nt
      my $status = $c->req->param('status');
      my $res = $nt->update({ status => $status });
  }

=head1 METHODS

=over 4

=item oauth

  $nt->oauth;

Returns Net::Twitter::OAuth::Simple object to deal with getting and setting
OAuth tokens.

=back

=head1 DELEGATED METHODS

The following method calls are delegated to the internal C<Net::Twitter::OAuth::Simple>
object.  I.e., these calls are identical:

    $nt->authorized;
    $nt->oauth->authorized;

See L<Net::OAuth::Simple> and L<Net::Twitter::OAuth::Simple> for full documentation.

=over 4

=item authorized

Whether the client has the necessary credentials to be authorized.

Note that the credentials may be wrong and so the request may fail.

=item request_access_token [PIN]

Request the access token and access token secret for this user.

The user must have authorized this app at the url given by C<get_authorization_url> first.

For desktop applications, the Twitter authorization page will present the user
with a PIN number.  Prompt the user for the PIN number, and pass it as an
argument to request_access_token.

Returns the access token and access token secret but also sets them internally
so that after calling this method, you can immediately call API methods
requiring authentication.

=item get_authorization_url

Get the URL used to authorize the user.  Returns a C<URI> object.

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

