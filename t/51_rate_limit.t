#!perl
use warnings;
use strict;
use Test::More;
use JSON qw/to_json/;
use lib qw(t/lib);
use Net::Twitter;

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required' if $@;

my $nt = Net::Twitter->new(traits => [qw/API::REST RateLimit/]);

my $reset = time + 1800;
my $t = TestUA->new(1, $nt->ua);
$t->response->content(to_json({
    remaining_hits        => 75,
    reset_time_in_seconds => $reset,
    hourly_limit          => 150,
}));

is   $nt->rate_limit,     150,    'rate_limit';
is   $nt->rate_remaining, 75,     'rate_remaining';
is   $nt->rate_reset,     $reset, 'rate_reset';
like $t->request->uri, qr/rate_limit_status/, 'rate_limit_status called';

# HACK! Test approxmate values
my $ratio = $nt->rate_ratio;
ok   $ratio > 0.9 && $ratio < 1.1, 'rate_ratio is about 1.0';

my $until = $nt->until_rate(2.0);
ok   $until > 890 && $until < 910, 'until_rate(2.0) is about 900';


# test clock mismatch
$t->response->content(to_json({
    remaining_hits        => 10,
    reset_time_in_seconds => $nt->_rate_limit_status->{rate_reset} = time - 10,
    hourly_limit          => 150,
}));

ok   $nt->rate_reset >= time, 'clock fudged';
is   $nt->rate_remaining, 10, 'forced a rate_limit_status call';

done_testing;
