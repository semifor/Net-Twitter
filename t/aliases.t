#!perl
use warnings;
use strict;
use Net::Twitter;
use Test::More;
use Test::Warn;

my $nt = Net::Twitter->new(
    ssl  => 0,
    user => 'foo',
    pass => 'bar',
);

is $nt->username, 'foo', 'user alias';
is $nt->password, 'bar', 'pass alias';

{ # ensure it warns

    my @args = (
        ssl      => 0,
        username => 'foo',
        password => 'bar',
        user     => 'other',
        pass     => 'other-pass',
    );

    warnings_like { Net::Twitter->new(@args) } [
        qr/Both username and user provided/,
        qr/Both password and pass provided/,
    ], 'you have been warned';
}

done_testing;
