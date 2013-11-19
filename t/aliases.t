#!perl
use warnings;
use strict;
use Net::Twitter;
use Test::More;

my $nt = Net::Twitter->new(
    user => 'foo',
    pass => 'bar',
);

is $nt->username, 'foo';
is $nt->password, 'bar';

done_testing;
