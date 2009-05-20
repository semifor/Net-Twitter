#!/usr/bin/perl
use warnings;
use strict;
use Template;
use lib qw(lib);
use Net::Twitter::Lite::API::REST;
use Net::Twitter::Lite::API::Search;

my $version = shift @ARGV;

my %args_for = (
    'src/net-twitter-pod.tt2' => [
        'lib/Net/Twitter.pod',
        'Net::Twitter::API::REST',
    ],
    'src/net-twitter-search-pod.tt2' => [
        'lib/Net/Twitter/Search.pod',
        'Net::Twitter::API::Search',
    ],
);

my $tt = Template->new;
for my $input ( keys %args_for ) {
    my ($output, $api) = @{$args_for{$input}};
    $tt->process($input, { VERSION => $version, api_def => $api->definition }, $output)
        || die $tt->error;
}

exit 0;
