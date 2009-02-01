#!/usr/bin/perl
use warnings;
use strict;
use Template;
use lib qw(lib);
use aliased 'Net::Twitter::Lite::API::REST' => 'API';

my $tt = Template->new;
$tt->process('src/net-twitter-lite-pm.tt2',
             { api_def => API->definition },
             'lib/Net/Twitter/Lite.pm'
) || die $tt->error;

exit 0;
