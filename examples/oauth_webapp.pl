#!/usr/bin/perl
#
# Net::Twitter - OAuth webapp example
#
package MyWebApp;
use warnings;
use strict;
use base qw/HTTP::Server::Simple::CGI/;

use Net::Twitter;
use Data::Dumper;

# You can replace the consumer tokens with your own;
# these tokens are for the Net::Twitter example app.
my %consumer_tokens = (
    consumer_key    => 'v8t3JILkStylbgnxGLOQ',
    consumer_secret => '5r31rSMc0NPtBpHcK8MvnCLg2oAyFLx5eGOMkXM',
);

my $server_port = 8080;

sub twitter { shift->{twitter} ||= Net::Twitter->new(traits => [qw/API::RESTv1_1/], %consumer_tokens) }

my %dispatch = (
    '/oauth_callback' => \&oauth_callback,
    '/'               => \&my_last_tweet,
);


# all request start here
sub handle_request {
    my ($self, $q) = @_;

    my $request = $q->path_info;
    warn "Handling request for $request\n";

    my $handler = $dispatch{$request} || \&not_found;
    $self->$handler($q);
}

# Display the authenicated user's last tweet in all its naked glory
sub my_last_tweet {
    my ($self, $q) = @_;

    # if the user is authorized, we'll get access tokens from a cookie
    my %sess = $q->cookie('sess');

    unless ( exists $sess{access_token_secret} ) {
        warn "User has no access_tokens\n";
        return $self->authorize($q);
    }

    warn <<"";
Using access tokens:
   access_token        => $sess{access_token}
   access_token_secret => $sess{access_token_secret}

    my $nt = $self->twitter;

    # pass the access tokens to Net::Twitter
    $nt->access_token($sess{access_token});
    $nt->access_token_secret($sess{access_token_secret});

    # attempt to get the user's last tweet
    my $status = eval { $nt->user_timeline({ count => 1 }) };
    if ( $@ ) {
        warn "$@\n";

        # if we got a 401 response, our access tokens were invalid; get new ones
        return $self->authorize($q) if $@ =~ /\b401\b/;

        # something bad happened; show the user the error
        $status = $@;
    }

    print $q->header(-nph => 1),
          $q->start_html,
          $q->pre(Dumper $status),
          $q->end_html;
}

# send the user to Twitter to authorize us
sub authorize {
    my ($self, $q) = @_;

    my $auth_url = $self->twitter->get_authorization_url(callback => "$ENV{SERVER_URL}oauth_callback");

    # we'll store the request tokens in a session cookie
    my $cookie = $q->cookie(-name => 'sess', -value => {
        request_token        => $self->twitter->request_token,
        request_token_secret => $self->twitter->request_token_secret,
    });

    warn "Sending user to: $auth_url\n";
    print $q->redirect(-nph => 1, -uri => $auth_url, -cookie => $cookie);
}

# Twitter returns the user here
sub oauth_callback {
    my ($self, $q) = @_;

    my $request_token = $q->param('oauth_token');
    my $verifier      = $q->param('oauth_verifier');

    my %sess = $q->cookie(-name => 'sess');
    die "Something is horribly wrong" unless $sess{request_token} eq $request_token;

    $self->twitter->request_token($request_token);
    $self->twitter->request_token_secret($sess{request_token_secret});

    warn <<"";
User returned from Twitter with:
    oauth_token    => $request_token
    oauth_verifier => $verifier

    # exchange the request token for access tokens
    my @access_tokens = $self->twitter->request_access_token(verifier => $verifier);

    warn <<"";
Exchanged request tokens for access tokens:
    access_token        => $access_tokens[0]
    access_token_secret => $access_tokens[1]

    # we'll store the access tokens in a session cookie
    my $cookie = $q->cookie(-name => 'sess', -value => {
        access_token        => $access_tokens[0],
        access_token_secret => $access_tokens[1],
    });

    warn "redirecting newly authorized user to $ENV{SERVER_URL}\n";
    print $q->redirect(-nph => 1, -uri => "$ENV{SERVER_URL}", -cookie => $cookie);
}

# display a 404 Not found for any request we don't expect
sub not_found {
    my ($self, $q) = @_;

    print $q->header(-nph => 1, -type => 'text/html', -status => '404 Not found'),
          $q->start_html,
          $q->h1('Not Found'),
          $q->p('You appear to be lost. Try going home.');
}

my $app = MyWebApp->new($server_port);
$app->run;
