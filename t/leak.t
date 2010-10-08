#!perl
use warnings;
use strict;
use Test::More tests => 2;
use Net::Twitter;

# Net::Twitter::Role::RateLimit 3.13009 memory leak
{
    package t::NT;
    use Moose;
    extends 'Net::Twitter::Core';
    with qw/
        Net::Twitter::Role::API::REST
        Net::Twitter::Role::RateLimit
    /;

    our $count = 0;

    sub BUILD { ++$count }
    sub DEMOLISH { --$count }
}


{
    my $nt = t::NT->new(consumer_key => 'foo', consumer_secret => 'bar');
    is $t::NT::count, 1, "BUILT";
}

is $t::NT::count, 0, "DEMOLISHED",
