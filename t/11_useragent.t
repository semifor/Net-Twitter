#!perl

use warnings;
use strict;

use Test::More tests => 3;
use Test::Exception;

use_ok 'Net::Twitter';

my $nt;
lives_ok { $nt = Net::Twitter->new(useragent_args => { timeout => 20 }) }
         'object creation with useragent_args';

is $nt->ua->timeout, 20, 'useragent_args applied';
