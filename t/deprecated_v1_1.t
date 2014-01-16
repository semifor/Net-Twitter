#!perl
use warnings;
use strict;
use Test::More;
use Test::Warn;
use lib qw(t/lib);

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

my $screen_name = 'net_twitter';
my $message_id  = 1234;
my $status      = 'Hello, world!';

my @tests = (
    [ disable_notifications  => sub { [ $screen_name ] }, { screen_name => $screen_name, device => 'false' }, POST => "/friendships/update.json", __LINE__ ],
    [ disable_notifications  => sub { [ { screen_name => $screen_name } ] }, { screen_name => $screen_name, device => 'false' }, POST => "/friendships/update.json", __LINE__ ],
    [ enable_notifications   => sub { [ $screen_name ] }, { screen_name => $screen_name, device => 'true' }, POST => "/friendships/update.json", __LINE__ ],
    [ enable_notifications   => sub { [ { screen_name => $screen_name } ] }, { screen_name => $screen_name, device => 'true' }, POST => "/friendships/update.json", __LINE__ ],
    [ friendship_exists      => sub { [ 'a', 'b'              ] }, { source_screen_name => 'a', target_screen_name => 'b' }, GET  => "/friendships/show.json", __LINE__, '{"relationship":{"target":{"followed_by":true}}}' ],
    [ new_direct_message     => sub { [ $screen_name, { text => $status } ] }, { screen_name => $screen_name, text => $status }, POST => "/direct_messages/new.json", __LINE__ ],
    [ new_direct_message     => sub { [ $screen_name, $status ] }, { screen_name => $screen_name, text => $status }, POST => "/direct_messages/new.json", __LINE__ ],
    [ new_direct_message     => sub { [ { user => $screen_name, text => $status } ] }, { screen_name => $screen_name, text => $status }, POST => "/direct_messages/new.json", __LINE__ ],
    [ new_direct_message     => sub { [ 1234, $status ] }, { user_id => 1234, text => $status }, POST => "/direct_messages/new.json", __LINE__ ],
);

plan tests => @tests + 1;

use_ok 'Net::Twitter';

my $nt = Net::Twitter->new(
    ssl      => 0,
    traits   => [qw/API::RESTv1_1/],
    username => 'homer',
    password => 'doh!',
);

my $t = TestUA->new(1.1, $nt->ua);

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

    warning_like { $nt->$api_call(@$input_args) } qr/deprecated/i, "[line $line] $api_call";

    $t->reset_response;
}

exit 0;
