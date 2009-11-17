#!perl
use warnings;
use strict;
use Test::More tests => 3 + 4 * 3 + 5;

use_ok 'Net::Twitter::Search';
use_ok 'Net::Twitter::OAuth';
use_ok 'Net::Identica';

sub does_legacy_roles {
    my $nt = shift;
    ok $nt->does($_) for map "Net::Twitter::Role::$_",
                          qw/Legacy API::REST API::Search WrapError/;
}

my $nt = Net::Twitter::Search->new;
does_legacy_roles($nt);
like  $nt->apiurl,   qr/twitter/,     'twitter url';
is    $nt->apihost, 'api.twitter.com:80', 'twitter host';

$nt = Net::Twitter::OAuth->new(consumer_key => 'key', consumer_secret => 'secret');
does_legacy_roles($nt);
ok $nt->does('Net::Twitter::Role::OAuth');

$nt = Net::Identica->new;
does_legacy_roles($nt);
like $nt->apiurl,   qr/identi[.]ca/, 'identica url';
is   $nt->apihost, 'identi.ca:80',  'identica host';

