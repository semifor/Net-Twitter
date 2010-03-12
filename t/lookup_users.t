#!perl
use warnings;
use strict;
use Test::More;
use Net::Twitter;

eval "use LWP::UserAgent 5.819";
plan skip_all => 'LWP::UserAgent >= 5.819 required' if $@;

eval "use Test::Deep";
plan skip_all => 'Test::Deep required' if $@;

my @tests = (
    {
        args   => [ { user_id => '1234,6543,3333' } ],
        expect => { user_id => [ 1234, 6543, 3333 ] },
        name   => 'hash: comma delimited',
    },
    {
        args   => [ user_id => '1234,6543,3333' ],
        expect => { user_id => [ 1234, 6543, 3333 ] },
        name   => 'list: comma delimited',
    },
    {
        args   => [ { user_id => [ 1234, 6543, 3333 ] } ],
        expect => { user_id => [ 1234, 6543, 3333 ] },
        name   => 'hash: arrayref',
    },
    {
        args   => [ { screen_name => 'fred,barney,wilma' } ],
        expect => { screen_name => [qw/fred barney wilma/] },
        name   => 'hash: comma delimited',
    },
    {
        args   => [ screen_name => ['fred', 'barney', 'wilma'] ],
        expect => { screen_name => [qw/fred barney wilma/] },
        name   => 'list: arrayref',
    },
    {
        args   => [ screen_name => ['fred', 'barney' ], user_id => '4321,6789' ],
        expect => { screen_name => [qw/fred barney/], user_id => [ 4321, 6789 ] },
        name   => 'list: arrayref screen_name and comma delimited user_id',
    },
);

my $test_count = 0;
$test_count += keys %$_ for map { $_->{expect} } @tests;

plan tests => $test_count;

my $nt = Net::Twitter->new(legacy => 0);

my $req;
$nt->ua->add_handler(request_send => sub {
    $req = shift;
    my $res = HTTP::Response->new(200);
    $res->content('{"test":"ok"}');
    return $res;
});

for my $test ( @tests ) {
    my $r = $nt->lookup_users(@{ $test->{args} });

    my %query = $req->uri->query_form;
    for my $arg ( keys %{ $test->{expect} } ) {
        cmp_bag([ split /,/, $query{$arg} ], $test->{expect}{$arg}, "$test->{name} [$arg]");
    }
}

