#!perl
use warnings;
use strict;
use Test::More;
use Test::Exception;
use lib qw(t/lib);
use Net::Twitter;

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

plan tests => 13;

my $nt = Net::Twitter->new(legacy => 1);
isa_ok $nt, 'Net::Twitter';

$nt = Net::Twitter->new(legacy => 0);
my $t = TestUA->new($nt->ua);

lives_ok { $nt->user_timeline } "lives without credentials";
ok       !$t->request->header('Authorization'), "no auth header without credentials";

$nt->credentials(homer => 'doh!');
lives_ok { $nt->user_timeline } "lives with credentials";
like     $t->request->header('Authorization'), qr/Basic/, "has Basic Auth header";

$nt->public_timeline;
ok       $t->request->header('Authorization'), "public timeline auths by default";

$nt->public_timeline({ authenticate => 0 });
ok       !$t->request->header('Authorization'), "public timeline can auth";

$nt->public_timeline({ authenticate => 1 });
ok       $t->request->header('Authorization'), "can force authentication";

$nt->rate_limit_status({ authenticate => 0 });
ok       !$t->request->header('Authorization'), "rate_limit_status allows no-auth";

$nt->rate_limit_status;
ok       $t->request->header('Authorization'), "rate_limit_status defaults to auth";

$nt = Net::Twitter->new(
    traits              => [qw/API::REST OAuth/],
    consumer_key        => 'com key',
    consumer_secret     => 'com secret',
);
$t = TestUA->new($nt->ua);

lives_ok { $nt->user_timeline } "lives without oauth tokens";
ok      !$t->request->header('Authorization'), "no auth header without access tokens";

$nt->access_token('1234');
$nt->access_token_secret('5678');
lives_ok { $nt->user_timeline } "lives with access tokens";
