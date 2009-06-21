#!perl

use warnings;
use strict;
use Test::More tests => 4;

use lib qw(t/lib);

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required for tests' if $@;

use_ok 'Net::Twitter';

my $nt = Net::Twitter->new(legacy => 0, identica => 1);
my $t = TestUA->new($nt->ua);

$t->response->content('"true"');
my $r = $nt->follows('night', 'day');
ok $r, 'string "true" is true';

$t->response->content('"false"');
$r = $nt->follows('night', 'day');
ok !$r, 'string "false" is false';

# and when they finally get it right:
$t->response->content('"true"');
$r = $nt->follows('night', 'day');
ok $r, 'bool true is true';
