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
    [ account_settings       => sub { [] }, {}, GET => '/account/settings.json', __LINE__ ],
    [ add_list_member        => sub { [ { list_id => 1234, user_id => 5678 } ] }, { list_id => 1234, user_id => 5678 }, POST => '/lists/members/create.json', __LINE__ ],
    [ add_place              => sub { [ 'hacker nest', 'baadf00d', '1234', 49, -122 ] }, { name => 'hacker nest', contained_within => 'baadf00d', token => 1234, lat => 49, long => -122 }, POST => '/geo/place.json', __LINE__ ],
    [ blocking               => sub { [] }, {}, GET => '/blocks/list.json', __LINE__ ],
    [ blocking_ids           => sub { [ { cursor => -1 } ] }, { cursor => -1 }, GET => '/blocks/ids.json', __LINE__ ],
    [ contributees           => sub { [ { screen_name => $screen_name } ] }, { screen_name => $screen_name }, GET => '/users/contributees.json', __LINE__ ],
    [ contributors           => sub { [ { screen_name => $screen_name } ] }, { screen_name => $screen_name }, GET => '/users/contributors.json', __LINE__ ],
    [ create_block           => sub { [ $screen_name ] }, { screen_name => $screen_name }, POST => "/blocks/create.json", __LINE__   ],
    [ create_favorite        => sub { [ $message_id ] },  { id => $message_id },           POST => "/favorites/create.json", __LINE__ ],
    [ create_favorite        => sub { [ { id => $message_id } ] }, { id => $message_id },  POST => "/favorites/create.json", __LINE__ ],
    [ create_friend          => sub { [ $screen_name ] }, { screen_name => $screen_name }, POST => "/friendships/create.json", __LINE__ ],
    [ create_list            => sub { [ { name => 'my-list' } ] }, { name => 'my-list' }, POST => '/lists/create.json', __LINE__ ],
    [ create_saved_search    => sub { [ 'perl hacker' ] }, { query => 'perl hacker' }, POST => '/saved_searches/create.json', __LINE__ ],
    [ delete_list            => sub { [ { list_id => 1234 } ] }, { list_id => 1234 }, POST => '/lists/destroy.json', __LINE__ ],
    [ delete_list_member     => sub { [ { list_id => 1234, user_id => 678 } ] }, { list_id => 1234, user_id => 678 }, POST => '/lists/members/destroy.json', __LINE__ ],
    [ delete_saved_search    => sub { [ 1234 ] }, {}, POST => '/saved_searches/destroy/1234.json', __LINE__ ], 
    [ destroy_block          => sub { [ $screen_name ] }, { screen_name => $screen_name }, POST => "/blocks/destroy.json", __LINE__  ],
    [ destroy_direct_message => sub { [ $message_id  ] }, { id => $message_id }, POST => "/direct_messages/destroy.json", __LINE__ ],
    [ destroy_favorite       => sub { [ $message_id  ] }, { id => $message_id }, POST => "/favorites/destroy.json", __LINE__ ],
    [ destroy_favorite       => sub { [ { id => $message_id } ] }, { id => $message_id }, POST => "/favorites/destroy.json", __LINE__ ],
    [ destroy_friend         => sub { [ $screen_name ] }, { screen_name => $screen_name }, POST => "/friendships/destroy.json", __LINE__ ],
    [ destroy_status         => sub { [ $message_id  ] }, {}, POST => "/statuses/destroy/$message_id.json", __LINE__  ],
    [ destroy_status         => sub { [ { id => $message_id } ] }, {}, POST => "/statuses/destroy/$message_id.json", __LINE__  ],
    [ direct_messages        => sub { [] }, {},                    GET  => "/direct_messages.json", __LINE__               ],
    [ direct_messages_sent   => sub { [] }, {}, GET => '/direct_messages/sent.json', __LINE__ ],
    [ favorites              => sub { [] }, {},                    GET  => "/favorites/list.json", __LINE__                ],
    [ followers              => sub { [] }, {},                    GET  => "/followers/list.json", __LINE__            ],
    [ followers_ids          => sub { [ { screen_name => $screen_name, cursor => -1 } ] }, { screen_name => $screen_name, cursor => -1 }, GET => '/followers/ids.json', __LINE__ ],
    [ friends                => sub { [] }, {},                    GET  => "/friends/list.json", __LINE__              ],
    [ friends_ids            => sub { [ { screen_name => $screen_name, cursor => -1 } ] }, { screen_name => $screen_name, cursor => -1 }, GET => '/friends/ids.json', __LINE__ ],
    [ friendships_incoming   => sub { [] }, {}, GET => '/friendships/incoming.json', __LINE__ ],
    [ friendships_outgoing   => sub { [] }, {}, GET => '/friendships/outgoing.json', __LINE__ ],
    [ geo_id                 => sub { [ 'df51dec6f4ee2b2c' ] }, {}, GET => '/geo/id/df51dec6f4ee2b2c.json', __LINE__ ],
    [ geo_search             => sub { [ { query => 'spokane' } ] }, { query => 'spokane' }, GET => '/geo/search.json', __LINE__ ],
    [ get_configuration      => sub { [] }, {}, GET => '/help/configuration.json', __LINE__ ],
    [ get_languages          => sub { [] }, {}, GET => '/help/languages.json', __LINE__ ],
    [ get_lists              => sub { [ { screen_name => $screen_name } ] }, { screen_name => $screen_name }, GET => '/lists/list.json', __LINE__ ],
    [ get_lists              => sub { [] }, {}, GET => '/lists/list.json', __LINE__ ],
    [ get_privacy_policy     => sub { [] }, {}, GET => '/help/privacy.json', __LINE__ ],
    [ get_tos                => sub { [] }, {}, GET => '/help/tos.json', __LINE__ ],
    [ home_timeline          => sub { [] }, {}, GET => '/statuses/home_timeline.json', __LINE__ ],
    [ list_members           => sub { [ { list_id => 12334 } ] }, { list_id => 12334 }, GET => '/lists/members.json', __LINE__ ],
    [ list_memberships       => sub { [ { user_id => 1234 } ] }, { user_id => 1234 }, GET => '/lists/memberships.json', __LINE__ ],
    [ list_statuses          => sub { [ { list_id => 1234 } ] }, { list_id => 1234 }, GET => '/lists/statuses.json', __LINE__ ],
    [ list_subscribers       => sub { [ { list_id => 1234 } ] }, { list_id => 1234 }, GET => '/lists/subscribers.json', __LINE__ ],
    [ lookup_friendships     => sub { [ { user_id => [ 1234, 5678 ] } ] }, { user_id => '1234,5678' }, GET => '/friendships/lookup.json', __LINE__ ],
    [ lookup_users           => sub { [ { screen_name => [qw/foo bar baz/] } ] }, { screen_name => 'foo,bar,baz' }, GET => '/users/lookup.json', __LINE__ ],
    [ members_create_all     => sub { [ { list_id => 1234, screen_name => [qw/a b c/] } ] }, { list_id => 1234, screen_name => 'a,b,c' }, POST => '/lists/members/create_all.json', __LINE__ ],
    [ members_destroy_all    => sub { [ { list_id => 1234 } ] }, { list_id => 1234 }, POST => '/lists/members/destroy_all.json', __LINE__ ],
    [ mentions               => sub { [] },                        {}, GET  => "/statuses/mentions_timeline.json", __LINE__              ],
    [ new_direct_message     => sub { [ { user_id => 1234, text => $status } ] }, { user_id => 1234, text => $status }, POST => "/direct_messages/new.json", __LINE__ ],
    [ new_direct_message     => sub { [ { screen_name => $screen_name, text => $status } ] }, { screen_name => $screen_name, text => $status }, POST => "/direct_messages/new.json", __LINE__ ],
    [ no_retweet_ids         => sub { [] }, {}, GET => '/friendships/no_retweets/ids.json', __LINE__ ],
    [ oembed                 => sub { [ { id => 99530515043983360 } ] }, { id => 99530515043983360 }, GET => '/statuses/oembed.json', __LINE__ ],
    [ profile_banner         => sub { [ { screen_name => $screen_name } ] }, { screen_name => $screen_name }, GET => '/users/profile_banner.json', __LINE__ ],
    [ rate_limit_status      => sub { [ { resources => [qw/help statuses/] } ] }, { resources => 'help,statuses' }, GET  => "/application/rate_limit_status.json", __LINE__     ],
    [ rate_limit_status      => sub { [] }, {},                    GET  => "/application/rate_limit_status.json", __LINE__     ],
    [ remove_profile_banner  => sub { [] }, {}, POST => '/account/remove_profile_banner.json', __LINE__ ],
    [ report_spam            => sub { [ { screen_name => 'spammer' } ] }, { screen_name => 'spammer' }, POST => '/users/report_spam.json', __LINE__ ],
    [ retweet                => sub { [ 44556 ] }, {}, POST => '/statuses/retweet/44556.json', __LINE__ ],
    [ retweets               => sub { [ 44444 ] }, {}, GET => '/statuses/retweets/44444.json', __LINE__ ],
    [ retweets_of_me         => sub { [] }, {}, GET => '/statuses/retweets_of_me.json', __LINE__ ],
    [ reverse_geocode        => sub { [ 37, -122 ] }, { lat => 37, long => -122 }, GET => '/geo/reverse_geocode.json', __LINE__ ],
    [ saved_searches         => sub { [] }, {}, GET => '/saved_searches/list.json', __LINE__ ],
    [ search                 => sub { [ 'perl hacker' ] }, { q => 'perl hacker' }, GET => '/search/tweets.json', __LINE__ ],
    [ search_users           => sub { [ 'perl hacker' ] }, { q => 'perl hacker' }, GET => '/users/search.json', __LINE__],
    [ sent_direct_messages   => sub { [] },                        {}, GET  => "/direct_messages/sent.json", __LINE__          ],
    [ show_direct_message    => sub { [ 1234 ] }, { id => 1234 }, GET => '/direct_messages/show.json', __LINE__ ],
    [ show_list              => sub { [ { list_id => 1234 } ] }, { list_id => 1234 }, GET => '/lists/show.json', __LINE__ ],
    [ show_list_member       => sub { [ { list_id => 1234, screen_name => $screen_name } ] }, { list_id => 1234, screen_name => $screen_name }, GET => '/lists/members/show.json', __LINE__ ],
    [ show_list_subscriber   => sub { [ { list_id => 1234, user_id => 666 } ] }, { list_id => 1234, user_id => 666 }, GET => '/lists/subscribers/show.json', __LINE__ ],
    [ show_saved_search      => sub { [ 1234 ] }, {}, GET => '/saved_searches/show/1234.json', __LINE__ ],
    [ show_status            => sub { [ 12345678              ] }, {}, GET  => "/statuses/show/12345678.json", __LINE__    ],
    [ show_user              => sub { [ $screen_name          ] }, { screen_name => $screen_name }, GET  => "/users/show.json", __LINE__       ],
    [ similar_places         => sub { [ { name => 'spokane' } ] }, { name => 'spokane' }, GET => '/geo/similar_places.json', __LINE__ ],
    [ subscribe_list         => sub { [ { owner_screen_name => $screen_name, slug => 'some-list' }, ] }, { owner_screen_name => $screen_name, slug => 'some-list' }, POST => '/lists/subscribers/create.json', __LINE__ ],
    [ subscriptions          => sub { [ { screen_name => $screen_name } ] }, { screen_name => $screen_name }, GET => '/lists/subscriptions.json', __LINE__ ],
    [ suggestion_categories  => sub { [ { lang => 'en' } ] }, { lang => 'en' }, GET => '/users/suggestions.json', __LINE__ ],
    [ trends_available       => sub { [] }, {}, GET => '/trends/available.json', __LINE__ ],
    [ trends_closest         => sub { [ { lat => 37, long => -122 } ] }, { lat => 37, long => -122 }, GET => '/trends/closest.json', __LINE__ ],
    [ trends_place           => sub { [ 1234 ] }, { id => 1234 }, GET => '/trends/place.json', __LINE__ ],
    [ unsubscribe_list       => sub { [ { list_id => 1234 } ] }, { list_id => 1234 }, POST => '/lists/subscribers/destroy.json', __LINE__ ],
    [ update                 => sub { [ $status               ] }, { status => $status, source => 'twitterpm' }, POST => "/statuses/update.json", __LINE__               ],
    [ update_account_settings => sub { [ { lang => 'en' } ] }, { lang => 'en' }, POST => '/account/settings.json', __LINE__ ],
    [ update_delivery_device => sub { [ 'sms'                 ] }, { device => 'sms' }, POST => "/account/update_delivery_device.json", __LINE__ ],
    [ update_friendship      => sub { [ { screen_name => $screen_name, retweets => 0 } ] }, { screen_name => $screen_name, retweets => 'false' }, POST => '/friendships/update.json', __LINE__ ],
    [ update_list            => sub { [ { list_id => 1234, mode => 'private' } ] }, { list_id => 1234, mode => 'private' }, POST => '/lists/update.json', __LINE__ ],
    [ update_profile         => sub { [ { name => 'Barney' } ] }, { name => 'Barney' }, POST => "/account/update_profile.json", __LINE__     ],
    [ update_profile_background_image => sub { [ { image => 'binary' }          ] }, { image => 'binary' }, POST => "/account/update_profile_background_image.json", __LINE__      ],
    [ update_profile_banner  => sub { [ { banner => 'binary data here' } ] }, { banner => 'binary data here' }, POST => "/account/update_profile_banner.json", __LINE__  ],
    [ update_profile_colors  => sub { [ { profile_background_color => '#0000' } ] }, { profile_background_color => '#0000' }, POST => "/account/update_profile_colors.json", __LINE__                ],
    [ update_profile_image   => sub { [ { image => 'binary data here' }         ] }, { image => 'binary data here' }, POST => "/account/update_profile_image.json", __LINE__                 ],
    [ update_with_media      => sub { [ $status, 'binary data' ] }, { status => $status, 'media[]' => 'binary data' }, POST => '/statuses/update_with_media.json', __LINE__ ],
    [ user_suggestions       => sub { [ 'slug', { lang => 'en' } ] }, { lang => 'en' }, GET => '/users/suggestions/slug/members.json', __LINE__ ],
    [ user_suggestions_for   => sub { [ 'slug', { lang => 'en' } ] }, { lang => 'en' }, GET => '/users/suggestions/slug.json', __LINE__ ],
    [ user_timeline          => sub { [] },                        {}, GET  => "/statuses/user_timeline.json", __LINE__         ],
    [ verify_credentials     => sub { [] },                        {}, GET  => "/account/verify_credentials.json", __LINE__     ],
);

plan tests => @tests * 2 * 4 + 1;

use_ok 'Net::Twitter';

my $nt = Net::Twitter->new(
    traits   => [qw/API::RESTv1_1/],
    username => 'homer',
    password => 'doh!',
);

my $t = TestUA->new(1.1, $nt->ua);

# run 2 passes to ensure the first pass isn't changing internal state
for my $pass ( 1, 2 ) {
    for my $test ( @tests ) {
        my ($api_call, $input_args, $request_args, $method, $path, $line, $json_response) = @$test;

        # Fresh copy of args from a coderef because Net::Twitter is allowed to mutated any args hash
        # passed in.
        $input_args = $input_args->();

        if ( $json_response ) {
            my $res = HTTP::Response->new(200, 'OK');
            $res->content($json_response);
            $t->response($res);
        }

        ok $nt->$api_call(@$input_args), "[$pass][line $line] $api_call call";

        is_deeply $t->args,         $request_args, "[$pass] $api_call args";
        is $t->path,                $path,         "[$pass] $api_call path";
        is $t->method,              $method,       "[$pass] $api_call method";

        $t->reset_response;
    }
}

exit 0;
