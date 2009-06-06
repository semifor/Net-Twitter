#!perl

use warnings;
use strict;

use lib qw(t/lib);
use Mock::LWP::UserAgent;

use Test::More tests => 4;

use_ok 'Net::Twitter';

# Net really dependent upon identica => 1, which fouls Mock::LWP::UserAgent,
# anyway.
my $nt = Net::Twitter->new(legacy => 0);
my $ua = $nt->ua;

$ua->set_response({ code => 200, message => 'OK', content => '"true"' });
my $r = $nt->follows('night', 'day');
ok $r, 'string "true" is true';

$ua->set_response({ code => 200, message => 'OK', content => '"false"' });
$r = $nt->follows('night', 'day');
ok !$r, 'string "false" is false';

# and when they finally get it right:
$ua->set_response({ code => 200, message => 'OK', content => 'true' });
$r = $nt->follows('night', 'day');
ok $r, 'bool true is true';
