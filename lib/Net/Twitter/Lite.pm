package Net::Twitter::Lite;
use 5.008;
use Moose;
use Carp;
use JSON::Any qw/XS DWIW JSON/;
use URI::Escape;

# use *all* digits for fBSD ports
our $VERSION = '0.00000_01';

$VERSION = eval $VERSION; # numify for warning-free dev releases

has useragent_class => ( isa => 'Str', is => 'ro', default => 'LWP::UserAgent' );
has username        => ( isa => 'Str', is => 'ro' );
has password        => ( isa => 'Str', is => 'ro' );
has useragent       => ( isa => 'Str', is => 'ro', default => __PACKAGE__ . "/$VERSION" );
has source          => ( isa => 'Str', is => 'ro', default => 'twitterpm' );
has apiurl          => ( isa => 'Str', is => 'ro', default => 'http://twitter.com' );
has apihost         => ( isa => 'Str', is => 'ro', default => 'twitter.com:80' );
has apirealm        => ( isa => 'Str', is => 'ro', default => 'Twitter API' );
has compat_mode     => ( isa => 'Bool', is => 'rw', default => 0 );
has _ua             => ( isa => 'Object', is => 'rw' );
has _response       => ( isa => 'HTTP::Response', is => 'rw' );

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

my %api_def = (
    create_block           => [ [ 'id' ], 1 => "blocks/create/ID"                ],
    create_favorite        => [ [ 'id' ], 1 => "favorites/create/ID"             ],
    create_friend          => [ [ 'id' ], 1 => "friendships/create/ID"           ],
    destroy_block          => [ [ 'id' ], 1 => "blocks/destroy/ID"               ],
    destroy_direct_message => [ [ 'id' ], 1 => "direct_messages/destroy/ID"      ],
    destroy_favorite       => [ [ 'id' ], 1 => "favorites/destroy/ID"            ],
    destroy_friend         => [ [ 'id' ], 1 => "friendships/destroy/ID"          ],
    destroy_status         => [ [ 'id' ], 1 => "statuses/destroy/ID"             ],
    direct_messages        => [ [],       0 => "direct_messages"                 ],
    disable_notifications  => [ [ 'id' ], 1 => "notifications/leave/ID"          ],
    downtime_schedule      => [ [],       0 => "help/downtime_schedule"          ],
    enable_notifications   => [ [ 'id' ], 1 => "notifications/follow/ID"         ],
    end_session            => [ [],       1 => "account/end_session"             ],
    favorites              => [ [ 'id' ], 0 => "favorites"                       ],
    followers              => [ [ 'id' ], 0 => "statuses/followers"              ],
    friends                => [ [ 'id' ], 0 => "statuses/friends"                ],
    friends_timeline       => [ [],       0 => "statuses/friends_timeline"       ],
    new_direct_message     => [ [ qw/user text/ ], 1 => "direct_messages/new"    ],
    public_timeline        => [ [],       0 => "statuses/public_timeline"        ],
    rate_limit_status      => [ [],       0 => "account/rate_limit_status"       ],
    relationship_exists    => [ [ qw/user_a user_b/ ], 0 => "friendships/exists" ],
    replies                => [ [],       0 => "statuses/replies"                ],
    sent_direct_messages   => [ [],       0 => "direct_messages/sent"            ],
    show_status            => [ [ 'id' ], 0 => "statuses/show/ID"                ],
    show_user              => [ [ 'id' ], 0 => "users/show/ID"                   ],
    test                   => [ [],       0 => "help/test"                       ],
    update                 => [ [ 'status' ], 1 => "statuses/update"             ],
    update_delivery_device => [ [ 'device' ], 1 => "account/update_delivery_device" ],
    update_profile         => [ [], 1 => "account/update_profile"                ],
    update_profile_background_image => [ [ 'image' ], 1 => "account/update_profile_background_image" ],
    update_profile_colors  => [ [], 1 => "account/update_profile_colors"         ],
    update_profile_image   => [ [ 'image' ], 1 => "account/update_profile_image" ],
    user_timeline          => [ [ 'id' ], 0 => "statuses/user_timeline"          ],
    verify_credentials     => [ [],       0 => "account/verify_credentials"      ],
);

sub BUILD {
    my $self = shift;

    eval "use " . $self->useragent_class;
    croak $@ if $@;

    my $ua = $self->_ua($self->useragent_class->new);
    $ua->credentials($self->apihost, $self->apirealm, $self->username, $self->password)
        if $self->username;
}

sub get_error { shift->_response->content }
sub http_code { shift->_response->code }
sub http_message { shift->_response->message }

my $post_request = sub {
    my ($ua, $uri, $args) = @_;
    return $ua->post($uri, $args);
};

my $get_request = sub {
    my ($ua, $uri, $args) = @_;
    $uri->query_form($args);
    return $ua->get($uri);
};

my $without_url_arg = sub { $_[0] };

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

for my $method ( keys %api_def ) {
    my ($arg_names, $post, $path) = @{$api_def{$method}};
    my $request = $post ? $post_request : $get_request;

    my $modify_path = $path =~ s/ID// ? $with_url_arg : $without_url_arg;
    my $extra_args = $method eq 'update' ? sub { { source => $_[0]->source } } : sub { {} };

    __PACKAGE__->meta->add_method($method, sub {
        my $self = shift;

        my $args = $extra_args->($self);
        if ( @_ ) {
            if ( !ref $_[0] ) {
                @_ == @$arg_names || croak "$method expected @{[ scalar @$arg_names ]} args";
                @{$args}{@$arg_names} = @_;
            }
            else {
                UNIVERSAL::isa($_[0], 'HASH') || croak "$method expected a HashRef";
                $args = { %$args, %{shift()} };
                @_ && croak "Too many args, $method expected a single HashRef";
            }
        }

        my $local_path = $modify_path->($path, $args);
        my $uri = URI->new("http://twitter.com/$local_path.json");
        my $res = $self->_response($request->($self->_ua, $uri, $args));
        my $obj = eval { JSON::Any->from_json($res->content) };

        return $obj if $res->is_success && $obj;
        return $res->is_success && $obj if $self->compat_mode;
        TwitterException->throw(
            error         => $obj->{error},
            http_response => $res,
            twitter_error => $obj
        ) if $obj;
        HttpException->throw(
            error         => $res->message,
            http_response => $res,
        );
    });
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Twitter::Lite - A lean perl interface to the Twitter API

=head1 SYNOPSIS

  use Net::Twitter::Light;

  my $ntl = Net::Twitter::Light->new(username => $user, password => $password);

  my $result = $ntl->update('Hello, world!');

  eval {
      my $feed = $ntl->friends_timeline({ since_id => $high_water, count => 100 });
      for my $status ( @$feed ) {
          say "$status->{user}{screen_name}: $status->{text};
      }
  };
  if ( @_ ) {
      if( my $e = TwitterException->caught() ) {
          warn "$e\n";
      }
      elsif ( $e = HttpException->caught() ) {
          warn "Network connection down?\n";
      }
      else {
          die $@; # something bad happened
      }
  }

  # Net::Twitter compatibility mode
  my $ntl = Net::Twitter::Lite->new(
      compat_mode => 1,
      username    => $user,
      password    => $password,
  my $feed = $ntl->friend_timeline;
  if ( $feed ) {
      for my $satus ( @$feed ) { ... }
  }
  else {
      warn "error: HTML resposes code ", $ntl->http_code, "\n";
  }

=head1 DESCRIPTION

C<Net::Twitter::Lite> attempts to provide a lean, robust, and easy to maintain
perl interface to the Twitter API. It provides some basic compatibility with
the L<Net::Twitter> module.  It takes a different approach in some areas,
however, so it is not a drop-in replacement.

Most Twitter API methods take parameters.  All C<Net::Twitter::Lite> methods
will accept a hash ref of named parameters as specified in the Twitter API
documentation.  For convenience, many C<Net::Twitter::Lite> methods accept
simple placeholder arguments as documented, below.  The placeholder parameter
passing style is optional; you can always use the named parameters in a hash
ref if you prefer.

C<Net::Twitter::Lite> does not do aggressive parameter validation. It will
dutifully pass invalid parameters to Twitter if instructed, and if Twitter
returns an error as a result, C<Net::Twitter::Lite> will throw an appropriate
exception.

The lack of aggressive parameter checking has an advantage.  If Twitter adds
new parameters to any of the API methods, you may begin using them immediately
without warning or errors and without any need for modification to the source
code of this module.

C<Net::Twitter::Lite> differs from C<Net::Twitter> significantly in its error
handling strategy.  It throws exceptions in response to Twitter and network
errors.  You can catch and deal with these errors using eval blocks in the
usual way.  Throwing exceptions allows C<Net::Twitter::Lite> to work well with
C<LWP::UserAgent::POE> in an environment where there may be concurrent
requests.

For compatibility with C<Net::Twitter>, C<Net::Twitter::Lite> provides a
C<compat_mode> option to C<new>.  In compatibility mode, C<Net::Twitter::Lite>
will return C<undef> on error.  Use the C<get_error>, C<http_code>, and
C<http_message> methods to determine the nature of the error.


=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

Copyright (c) 2009 Marc Mims

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
