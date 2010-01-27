#!perl
use warnings;
use strict;
use Test::More;
use Net::Twitter;

eval 'use LWP::UserAgent 5.819';
plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

my $nt = Net::Twitter->new(traits => [qw/API::Lists/], user => 'fred', password => 'secret');

my $req;
my $res = HTTP::Response->new(200);
$res->content('{"response":"done"}');
$nt->ua->add_handler(request_send => sub { $req = shift; return $res });

my @tests = (
    create_list => {
        args   => [ 'owner', { name => 'Test list', description => 'Just a test', mode => 'private' } ],
        path   => '/owner/lists',
        params => { name => 'Test list', description => 'Just a test', mode => 'private' },
        method => 'POST',
    },
    update_list => {
        args   => [ 'owner', 'test-list', { mode => 'public' } ],
        path   => '/owner/lists/test-list',
        params => { mode => 'public' },
        method => 'POST',
    },
    list_lists => {
        args =>[ 'owner' ],
        path => '/owner/lists',
        params => {},
        method => 'GET',
    },
    list_memberships => {
        args => [ 'owner' ],
        path => '/owner/lists/memberships',
        params => {},
        method => 'GET',
    },
    delete_list => {
        args => [ 'owner', 'test-list' ],
        path => '/owner/lists/test-list',
        params => {},
        method => 'DELETE',
    },
    list_statuses => {
        args => [ 'owner', 'test-list' ],
        path => '/owner/lists/test-list/statuses',
        params => {},
        method => 'GET',
    },
    get_list => {
        args => [ 'owner', 'test-list' ],
        path => '/owner/lists/test-list',
        params => {},
        method => 'GET',
    },
    add_list_member => {
        args => [ 'owner', 'test-list', 1234 ],
        path => '/owner/test-list/members',
        params => { id => 1234 },
        method => 'POST',
    },
    delete_list_member => {
        args => [ 'owner', 'test-list', 1234 ],
        path => '/owner/test-list/members',
        params => { id => 1234 },
        method => 'DELETE',
    },
    remove_list_member => {
        args => [ 'owner', 'test-list', 1234 ],
        path => '/owner/test-list/members',
        params => { id => 1234 },
        method => 'DELETE',
    },
    list_members => {
        args => [ 'owner', 'test-list' ],
        path => '/owner/test-list/members',
        params => {},
        method => 'GET',
    },
    is_list_member => {
        args => [ 'owner', 'test-list', 1234 ],
        path => '/owner/test-list/members/1234',
        params => {},
        method => 'GET',
    },
    subscribe_list => {
        args => [ 'owner', 'some-list' ],
        path => '/owner/some-list/subscribers',
        params => {},
        method => 'POST',
    },
    list_subscribers => {
        args => [ 'owner', 'some-list' ],
        path => '/owner/some-list/subscribers',
        params => {},
        method => 'GET',
    },
    list_subscriptions => {
        args => [ 'owner' ],
        path => '/owner/lists/subscriptions',
        params => {},
        method => 'GET',
    },
    unsubscribe_list => {
        args => [ 'owner', 'test-list' ],
        path => '/owner/test-list/subscribers',
        params => {},
        method => 'DELETE',
    },
    is_list_subscriber => {
        args => [ 'owner', 'test-list', 1234 ],
        path => '/owner/test-list/subscribers/1234',
        params => {},
        method => 'GET',
    },
    is_subscribed_list => {
        args => [ 'owner', 'test-list', 1234 ],
        path => '/owner/test-list/subscribers/1234',
        params => {},
        method => 'GET',
    },
);

plan tests => scalar @tests / 2 * 3;

while ( @tests ) {
    my $api_method = shift @tests;
    my $t = shift @tests;

    my $r = $nt->$api_method(@{ $t->{args} });
    is $req->uri->path, "/1$t->{path}.json", "$api_method: path";
    is $req->method, $t->{method}, "$api_method: HTTP method";
    is_deeply extract_args($req), $t->{params},
        "$api_method: parameters";
}

sub extract_args {
    my $req = shift;

    my $uri;
    if ( $req->method eq 'POST' ) {
        $uri = URI->new;
        $uri->query($req->content);
    }
    else {
        $uri = $req->uri;
    }

    return { $uri->query_form };
}
