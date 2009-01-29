#!perl -wT
use strict;
use warnings;
use Test::More;

plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};

eval 'use Test::Pod 1.00';
plan skip_all => 'Test::Pod 1.00 not installed' if $@;

all_pod_files_ok();
