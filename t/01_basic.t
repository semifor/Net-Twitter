#!perl
use warnings;
use strict;
use Test::More;
use lib qw(t/lib);

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

my $screen_name = 'net_twitter';
my $message_id  = 1234;
my $status      = 'Hello, world!';

my @tests = (
    [ create_block           => [ $screen_name          ], POST => "/blocks/create/$screen_name.json", __LINE__   ],
    [ create_favorite        => [ $message_id           ], POST => "/favorites/create/$message_id.json", __LINE__ ],
    [ create_favorite        => [ { id => $message_id } ], POST => "/favorites/create/$message_id.json", __LINE__ ],
    [ create_friend          => [ $screen_name          ], POST => "/friendships/create/$screen_name.json", __LINE__ ],
    [ destroy_block          => [ $screen_name          ], POST => "/blocks/destroy/$screen_name.json", __LINE__  ],
    [ destroy_direct_message => [ $message_id           ], POST => "/direct_messages/destroy/$message_id.json", __LINE__ ],
    [ destroy_favorite       => [ $message_id           ], POST => "/favorites/destroy/$message_id.json", __LINE__ ],
    [ destroy_favorite       => [ { id => $message_id } ], POST => "/favorites/destroy/$message_id.json", __LINE__ ],
    [ destroy_friend         => [ $screen_name          ], POST => "/friendships/destroy/$screen_name.json", __LINE__ ],
    [ destroy_status         => [ $message_id           ], POST => "/statuses/destroy/$message_id.json", __LINE__  ],
    [ destroy_status         => [ { id => $message_id } ], POST => "/statuses/destroy/$message_id.json", __LINE__  ],
    [ direct_messages        => [],                        GET  => "/direct_messages.json", __LINE__               ],
    [ disable_notifications  => [ $screen_name          ], POST => "/notifications/leave/$screen_name.json", __LINE__ ],
    [ disable_notifications  => [ { id => $screen_name }], POST => "/notifications/leave/$screen_name.json", __LINE__ ],
    [ downtime_schedule      => [],                        GET  => "/help/downtime_schedule.json", __LINE__        ],
    [ enable_notifications   => [ $screen_name          ], POST => "/notifications/follow/$screen_name.json", __LINE__ ],
    [ enable_notifications   => [ { id => $screen_name }], POST => "/notifications/follow/$screen_name.json", __LINE__ ],
    [ end_session            => [],                        POST => "/account/end_session.json", __LINE__           ],
    [ favorites              => [],                        GET  => "/favorites.json", __LINE__                     ],
    [ followers              => [],                        GET  => "/statuses/followers.json", __LINE__            ],
    [ friends                => [],                        GET  => "/statuses/friends.json", __LINE__              ],
    [ friends_timeline       => [],                        GET  => "/statuses/friends_timeline.json", __LINE__     ],
    [ new_direct_message     => [ { user => $screen_name, text => $status } ],
             POST => "/direct_messages/new.json", __LINE__ ],
    [ new_direct_message     => [ $screen_name, $status ], POST => "/direct_messages/new.json", __LINE__ ],
    [ new_direct_message     => [ { user_id => 1234, text => $status } ],
             POST => "/direct_messages/new.json", __LINE__ ],
    [ new_direct_message     => [ { screen_name => $screen_name, text => $status } ],
             POST => "/direct_messages/new.json", __LINE__ ],
    [ public_timeline        => [],                        GET  => "/statuses/public_timeline.json", __LINE__      ],
    [ rate_limit_status      => [],                        GET  => "/account/rate_limit_status.json", __LINE__     ],
    [ friendship_exists      => [ 'a', 'b'              ], GET  => "/friendships/exists.json", __LINE__            ],
    # TODO: mentions -> replies, for now, to accommodate identica
    [ mentions               => [],                        GET  => "/statuses/replies.json", __LINE__              ],
    [ sent_direct_messages   => [],                        GET  => "/direct_messages/sent.json", __LINE__          ],
    [ show_status            => [ $screen_name          ], GET  => "/statuses/show/$screen_name.json", __LINE__    ],
    [ show_user              => [ $screen_name          ], GET  => "/users/show/$screen_name.json", __LINE__       ],
    [ test                   => [],                        GET  => "/help/test.json", __LINE__                     ],
    [ update                 => [ $status               ], POST => "/statuses/update.json", __LINE__               ],
    [ update_delivery_device => [ 'sms'                 ], POST => "/account/update_delivery_device.json", __LINE__ ],
    [ update_profile         => [ { name => $screen_name } ], POST => "/account/update_profile.json", __LINE__     ],
    [ update_profile_background_image => [ { image => 'binary' }          ],
             POST => "/account/update_profile_background_image.json", __LINE__      ],
    [ update_profile_colors  => [ { profile_background_color => '#0000' } ],
             POST => "/account/update_profile_colors.json", __LINE__                ],
    [ update_profile_image   => [ { image => 'binary data here' }         ],
             POST => "/account/update_profile_image.json", __LINE__                 ],
    [ user_timeline          => [],                        GET  => "/statuses/user_timeline.json", __LINE__         ],
    [ verify_credentials     => [],                        GET  => "/account/verify_credentials.json", __LINE__     ],
);

plan tests => @tests * 2 * 4 + 2;

use_ok 'Net::Twitter';

my $nt = Net::Twitter->new(legacy => 1);
isa_ok $nt, 'Net::Twitter';

$nt = Net::Twitter->new(
    legacy   => 0,
    username => 'homer',
    password => 'doh!',
);

my $t = TestUA->new($nt->ua);

# run 2 passes to ensure the first pass isn't changing internal state
for my $pass ( 1, 2 ) {
for my $test ( @tests ) {
    my ($api_call, $args, $method, $path, $line) = @$test;

    my %args;
    if ( $api_call eq 'update' ) {
        %args = ( source => 'twitterpm', status => @$args );
    }
    elsif ( @$args ) {
        if ( ref $args->[0] ) {
            %args = %{$args->[0]};
        }
        else {
           @{args}{@{$nt->meta->get_method($api_call)->required}} = @$args;
        }
    }

    ok $nt->$api_call(@$args),           "[$pass] $api_call call";

    # kludge: add the screen_name or message_id to the $t's arguments if either
    # exists in the path
    $t->add_id_arg($screen_name);
    $t->add_id_arg($message_id);

    is_deeply $t->args,         \%args,  "[$pass][line $line] $api_call args";
    is $t->path,                $path,   "[$pass][line $line] $api_call path";
    is $t->method,              $method, "[$pass][line $line] $api_call method";
}
}

exit 0;
