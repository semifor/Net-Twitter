#!/usr/bin/perl
use warnings;
use strict;
use Template;
use lib qw(lib);
use Net::Twitter::Lite::API::REST;
use Net::Twitter::Lite::API::Search;

my $version = shift @ARGV;

my %args_for = (
    'src/net-twitter-lite-pod.tt2' => [
        'lib/Net/Twitter/Lite.pod',
        'Net::Twitter::Lite::API::REST',
    ],
    'src/net-twitter-lite-search-pod.tt2' => [
        'lib/Net/Twitter/Lite/Search.pod',
        'Net::Twitter::Lite::API::Search',
    ],
);

my $tt = Template->new;
for my $input ( keys %args_for ) {
    my ($output, $api) = @{$args_for{$input}};
    $tt->process($input, { VERSION => $version, api_def => $api->definition }, $output)
        || die $tt->error;
}

exit 0;
