#!perl -wT
use warnings;
use strict;
use Test::More;

plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};

eval "use Pod::Coverage 0.19";
plan skip_all => 'Pod::Coverage 0.19 required' if $@;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;

plan skip_all => 'set TEST_POD to enable this test'
  unless ($ENV{TEST_POD} || -e 'MANIFEST.SKIP');

all_pod_coverage_ok({ trustme => [qw/API BUILD REST/] });
