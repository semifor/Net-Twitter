#!perl

use warnings;
use strict;

use Test::More tests => 3;
use Test::Fatal;

use_ok 'Net::Twitter';

my $nt;
is exception { $nt = Net::Twitter->new(ssl => 0, useragent_args => { timeout => 20 }) }, undef,
         'object creation with useragent_args';

is $nt->ua->timeout, 20, 'useragent_args applied';
