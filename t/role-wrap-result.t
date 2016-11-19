#!perl
use strict;
use warnings;
use Test::More;

use Net::Twitter;

my $nt = Net::Twitter->new(
    traits              => [ qw/API::RESTv1_1 WrapResult/ ],
    consumer_key        => 'my-key',
    consumer_secret     => 'my-secret',
    access_token        => 'token',
    access_token_secret => 'token-secret',
);

$nt->ua->add_handler(request_send => sub {
    HTTP::Response->new(
        200,
        'OK',
        [
            'X-Rate-Limit-Limit'     => 222,
            'X-Rate-Limit-Remaining' => 111,
            'X-Rate-Limit-Reset'     => 1234,
        ],
        '[1,2,3,4,5]',
    );
});

my $r = $nt->verify_credentials;

is $r->rate_limit,           222,  'rate limit';
is $r->rate_limit_remaining, 111,  'rate limit remaining';
is $r->rate_limit_reset,     1234, 'rate limit reset';

is_deeply $r->result, [ 1..5 ], 'twitter result';

done_testing;
