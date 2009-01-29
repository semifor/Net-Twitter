#!perl
use warnings;
use strict;
use Test::More;

# Originally written by Marc Mims for Net::Twitter, then modified for Net::Twitter::Lite

use lib qw(t/lib);

use Mock::LWP::UserAgent;

my $screen_name = 'net_twitter';
my $message_id  = 1234;
my $status      = 'Hello, world!';

my @tests = (
    [ create_block           => [ $screen_name          ], POST => "/blocks/create/$screen_name.json"   ],
    [ create_favorite        => [ $message_id           ], POST => "/favorites/create/$message_id.json" ],
    [ create_favorite        => [ { id => $message_id } ], POST => "/favorites/create/$message_id.json" ],
    [ create_friend          => [ $screen_name          ], POST => "/friendships/create/$screen_name.json" ],
    [ destroy_block          => [ $screen_name          ], POST => "/blocks/destroy/$screen_name.json"  ],
    [ destroy_direct_message => [ $message_id           ], POST => "/direct_messages/destroy/$message_id.json" ],
    [ destroy_favorite       => [ $message_id           ], POST => "/favorites/destroy/$message_id.json" ],
    [ destroy_favorite       => [ { id => $message_id } ], POST => "/favorites/destroy/$message_id.json" ],
    [ destroy_friend         => [ $screen_name          ], POST => "/friendships/destroy/$screen_name.json" ],
    [ destroy_status         => [ $message_id           ], POST => "/statuses/destroy/$message_id.json"  ],
    [ destroy_status         => [ { id => $message_id } ], POST => "/statuses/destroy/$message_id.json"  ],
    [ direct_messages        => [],                        GET  => "/direct_messages.json"               ],
    [ disable_notifications  => [ $screen_name          ], POST => "/notifications/leave/$screen_name.json" ],
    [ disable_notifications  => [ { id => $screen_name }], POST => "/notifications/leave/$screen_name.json" ],
    [ downtime_schedule      => [],                        GET  => "/help/downtime_schedule.json"        ],
    [ enable_notifications   => [ $screen_name          ], POST => "/notifications/follow/$screen_name.json" ],
    [ enable_notifications   => [ { id => $screen_name }], POST => "/notifications/follow/$screen_name.json" ],
    [ end_session            => [],                        POST => "/account/end_session.json"           ],
    [ favorites              => [],                        GET  => "/favorites.json"                     ],
    [ followers              => [],                        GET  => "/statuses/followers.json"            ],
    [ friends                => [],                        GET  => "/statuses/friends.json"              ],
    [ friends_timeline       => [],                        GET  => "/statuses/friends_timeline.json"     ],
    [ new_direct_message     => [ { user => $screen_name, text => $status } ],
             POST => "/direct_messages/new.json" ],
    [ public_timeline        => [],                        GET  => "/statuses/public_timeline.json"      ],
    [ rate_limit_status      => [],                        GET  => "/account/rate_limit_status.json"     ],
    [ relationship_exists    => [ 'a', 'b'              ], GET  => "/friendships/exists.json"            ],
    [ replies                => [],                        GET  => "/statuses/replies.json"              ],
    [ sent_direct_messages   => [],                        GET  => "/direct_messages/sent.json"          ],
    [ show_status            => [ $screen_name          ], GET  => "/statuses/show/$screen_name.json"    ],
    [ show_user              => [ $screen_name          ], GET  => "/users/show/$screen_name.json"       ],
    [ test                   => [],                        GET  => "/help/test.json"                     ],
    [ update                 => [ $status               ], POST => "/statuses/update.json"               ],
    [ update_delivery_device => [ 'sms'                 ], POST => "/account/update_delivery_device.json" ],
#[ update_profile         => [ { name => $screen_name } ], POST => "/account/update_profile.json"     ],
    [ update_profile_background_image => [ { image => 'binary' }          ],
             POST => "/account/update_profile_background_image.json"      ],
    [ update_profile_colors  => [ { profile_background_color => '#0000' } ],
             POST => "/account/update_profile_colors.json"                ],
    [ update_profile_image   => [ { image => 'binary data here' }         ],
             POST => "/account/update_profile_image.json"                 ],
    [ user_timeline          => [],                        GET  => "/statuses/user_timeline.json"         ],
    [ verify_credentials     => [],                        GET  => "/account/verify_credentials.json"     ],
);

plan tests => @tests * 2 * 4 + 1;

use_ok 'Net::Twitter::Lite';

my $nt = Net::Twitter::Lite->new(
    username => 'homer',
    password => 'doh!',
);

my $ua = $nt->_ua;

# run 2 passes to ensure the first pass isn't changing internal state
for my $pass ( 1, 2 ) {
for my $test ( @tests ) {
    my ($api_call, $args, $method, $path) = @$test;

    my %args;
    if ( $api_call eq 'update' ) {
        %args = ( source => 'twitterpm', status => @$args );
    }
    elsif ( $api_call eq 'relationship_exists' ) {
        @{args}{qw/user_a user_b/} = @$args;
    }
    elsif ( $api_call eq 'update_delivery_device' ) {
        %args = ( device => @$args );
    }
    elsif ( @$args ) {
        %args = ref $args->[0] ? %{$args->[0]} : ( id => $args->[0] );
    }

    ok $nt->$api_call(@$args),         "[$pass] $api_call call";
    is_deeply $ua->input_args, \%args, "[$pass] $api_call args";
    is $ua->input_uri->path, $path,    "[$pass] $api_call path";
    is $ua->input_method, $method,     "[$pass] $api_call method";
}
}

exit 0;
