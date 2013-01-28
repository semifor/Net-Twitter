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
    [ create_block           => sub { [ $screen_name ] }, { screen_name => $screen_name }, POST => "/blocks/create.json", __LINE__   ],
    [ create_favorite        => sub { [ $message_id ] },  { id => $message_id },           POST => "/favorites/create.json", __LINE__ ],
    [ create_favorite        => sub { [ { id => $message_id } ] }, { id => $message_id },  POST => "/favorites/create.json", __LINE__ ],
    [ create_friend          => sub { [ $screen_name ] }, { screen_name => $screen_name }, POST => "/friendships/create.json", __LINE__ ],
    [ destroy_block          => sub { [ $screen_name ] }, { screen_name => $screen_name }, POST => "/blocks/destroy.json", __LINE__  ],
    [ destroy_direct_message => sub { [ $message_id  ] }, { id => $message_id }, POST => "/direct_messages/destroy.json", __LINE__ ],
    [ destroy_favorite       => sub { [ $message_id  ] }, { id => $message_id }, POST => "/favorites/destroy.json", __LINE__ ],
    [ destroy_favorite       => sub { [ { id => $message_id } ] }, { id => $message_id }, POST => "/favorites/destroy.json", __LINE__ ],
    [ destroy_friend         => sub { [ $screen_name ] }, { screen_name => $screen_name }, POST => "/friendships/destroy.json", __LINE__ ],
    [ destroy_status         => sub { [ $message_id  ] }, {}, POST => "/statuses/destroy/$message_id.json", __LINE__  ],
    [ destroy_status         => sub { [ { id => $message_id } ] }, {}, POST => "/statuses/destroy/$message_id.json", __LINE__  ],
    [ direct_messages        => sub { [] }, {},                    GET  => "/direct_messages.json", __LINE__               ],
    [ disable_notifications  => sub { [ $screen_name ] }, { screen_name => $screen_name, device => 'false' }, POST => "/friendships/update.json", __LINE__ ],
    [ disable_notifications  => sub { [ { screen_name => $screen_name } ] }, { screen_name => $screen_name, device => 'false' }, POST => "/friendships/update.json", __LINE__ ],
    [ enable_notifications   => sub { [ $screen_name ] }, { screen_name => $screen_name, device => 'true' }, POST => "/friendships/update.json", __LINE__ ],
    [ enable_notifications   => sub { [ { screen_name => $screen_name } ] }, { screen_name => $screen_name, device => 'true' }, POST => "/friendships/update.json", __LINE__ ],
    [ favorites              => sub { [] }, {},                    GET  => "/favorites/list.json", __LINE__                ],
    [ followers              => sub { [] }, {},                    GET  => "/followers/list.json", __LINE__            ],
    [ friends                => sub { [] }, {},                    GET  => "/friends/list.json", __LINE__              ],
    [ friendship_exists      => sub { [ 'a', 'b'              ] }, { source_screen_name => 'a', target_screen_name => 'b' }, GET  => "/friendships/show.json", __LINE__, '{"relationship":{"target":{"followed_by":true}}}' ],
    [ mentions               => sub { [] },                        {}, GET  => "/statuses/mentions.json", __LINE__              ],
    [ new_direct_message     => sub { [ $screen_name, $status ] }, { screen_name => $screen_name, text => $status }, POST => "/direct_messages/new.json", __LINE__ ],
    [ new_direct_message     => sub { [ $screen_name, { text => $status } ] }, { screen_name => $screen_name, text => $status }, POST => "/direct_messages/new.json", __LINE__ ],
    [ new_direct_message     => sub { [ 1234, $status ] }, { user_id => 1234, text => $status }, POST => "/direct_messages/new.json", __LINE__ ],
    [ new_direct_message     => sub { [ { screen_name => $screen_name, text => $status } ] }, { screen_name => $screen_name, text => $status }, POST => "/direct_messages/new.json", __LINE__ ],
    [ new_direct_message     => sub { [ { user => $screen_name, text => $status } ] }, { screen_name => $screen_name, text => $status }, POST => "/direct_messages/new.json", __LINE__ ],
    [ new_direct_message     => sub { [ { user_id => 1234, text => $status } ] }, { user_id => 1234, text => $status }, POST => "/direct_messages/new.json", __LINE__ ],
    [ rate_limit_status      => sub { [ { resources => [qw/help statuses/] } ] }, { resources => 'help,statuses' }, GET  => "/application/rate_limit_status.json", __LINE__     ],
    [ rate_limit_status      => sub { [] }, {},                    GET  => "/application/rate_limit_status.json", __LINE__     ],
    [ sent_direct_messages   => sub { [] },                        {}, GET  => "/direct_messages/sent.json", __LINE__          ],
    [ show_status            => sub { [ 12345678              ] }, {}, GET  => "/statuses/show/12345678.json", __LINE__    ],
    [ show_user              => sub { [ $screen_name          ] }, { screen_name => $screen_name }, GET  => "/users/show.json", __LINE__       ],
    [ update                 => sub { [ $status               ] }, { status => $status, source => 'twitterpm' }, POST => "/statuses/update.json", __LINE__               ],
    [ update_delivery_device => sub { [ 'sms'                 ] }, { device => 'sms' }, POST => "/account/update_delivery_device.json", __LINE__ ],
    [ update_profile         => sub { [ { name => 'Barney' } ] }, { name => 'Barney' }, POST => "/account/update_profile.json", __LINE__     ],
    [ update_profile_background_image => sub { [ { image => 'binary' }          ] }, { image => 'binary' }, POST => "/account/update_profile_background_image.json", __LINE__      ],
    [ update_profile_colors  => sub { [ { profile_background_color => '#0000' } ] }, { profile_background_color => '#0000' }, POST => "/account/update_profile_colors.json", __LINE__                ],
    [ update_profile_image   => sub { [ { image => 'binary data here' }         ] }, { image => 'binary data here' }, POST => "/account/update_profile_image.json", __LINE__                 ],
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

        ok $nt->$api_call(@$input_args), "[$pass] $api_call call";

        is_deeply $t->args,         $request_args, "[$pass][line $line] $api_call args";
        is $t->path,                $path,         "[$pass][line $line] $api_call path";
        is $t->method,              $method,       "[$pass][line $line] $api_call method";

        $t->reset_response;
    }
}

exit 0;
