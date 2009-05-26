#!perl

use warnings;
use strict;

use lib qw(t/lib);
use Mock::LWP::UserAgent;

use Test::More tests => 4;

use_ok 'Net::Twitter';

# Net really dependent upon identica => 1, which fouls Mock::LWP::UserAgent,
# anyway.
my $nt = Net::Twitter->new;
my $ua = $nt->ua;

$ua->set_response({ code => 200, message => 'OK', content => '"true"' });
my $r = $nt->follows('night', 'day');
is $r, 1, 'string "true" is 1';

$ua->set_response({ code => 200, message => 'OK', content => '"false"' });
$r = $nt->follows('night', 'day');
ok !defined $r, 'string "false" is undef';

# and when they finally get it right:
$ua->set_response({ code => 200, message => 'OK', content => 'true' });
$r = $nt->follows('night', 'day');
is $r, 1, 'bool true is 1';
