package Net::Twitter::Lite;
use Moose;
use Carp;
use JSON::Any qw/XS DWIW JSON/;
use URI::Escape;

our $VERSION = '0.01';

has useragent_class => ( isa => 'Str', is => 'ro', default => 'LWP::UserAgent' );
has username        => ( isa => 'Str', is => 'ro' );
has password        => ( isa => 'Str', is => 'ro' );
has useragent       => ( isa => 'Str', is => 'ro', default => __PACKAGE__ . "/$VERSION" );
has source          => ( isa => 'Str', is => 'ro', default => 'twitterpm' );
has apiurl          => ( isa => 'Str', is => 'ro', default => 'http://twitter.com' );
has apihost         => ( isa => 'Str', is => 'ro', default => 'twitter.com:80' );
has apirealm        => ( isa => 'Str', is => 'ro', default => 'Twitter API' );
has _ua             => ( isa => 'Object', is => 'rw' );
has _response       => ( isa => 'HTTP::Response', is => 'rw' );

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
        if ( @_ && !ref $_[0] ) {
            @_ == @$arg_names || croak "$method expected @{[ scalar @$arg_names ]} args";
            @{$args}{@$arg_names} = @_;
        }
        else {
            if ( @_ ) {
                UNIVERSAL::isa($_[0], 'HASH') || croak "$method expected a HashRef";
                $args = { %$args, %{shift()} };
                @_ && croak "Too many args, $method expected a single HashRef";
            }
        }

        my $local_path = $modify_path->($path, $args);
        my $uri = URI->new("http://twitter.com/$local_path.json");
        my $res = $self->_response($request->($self->_ua, $uri, $args));

        return $res->is_success ? eval { JSON::Any->from_json($res->content) } : undef;
    });
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Twitter::Lite - A lean perl interface to the Twitter API

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

Copyright (c) 2009 Marc Mims. All rights reserved.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
