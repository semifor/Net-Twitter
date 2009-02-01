#!/usr/bin/perl
use warnings;
use strict;
use Template;
use lib qw(lib);
use aliased 'Net::Twitter::Lite::API';

my $tt = Template->new;
$tt->process('src/net-twitter-lite-pm.tt2',
             { api_def => [ @{API->definition('rest')}, @{API->definition('search')} ] },
             'lib/Net/Twitter/Lite.pm'
) || die $tt->error;

exit 0;
