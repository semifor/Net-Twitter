#!perl -wT
use warnings;
use strict;
use Test::More;

plan skip_all => 'set TEST_POD to enable this test'
  unless ($ENV{TEST_POD} || -e 'MANIFEST.SKIP');

eval "use Pod::Coverage 0.19";
plan skip_all => 'Pod::Coverage 0.19 required' if $@;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => 'Test::Pod::Coverage 1.04 required' if $@;

all_pod_coverage_ok({
    also_private => [qr/^BUILD(:?ARGS)?$/],
    trustme      => [
        qr/^credentials|isa$/,                  # Core::credentials
        qr/^allow_extra_params|sign_message$/,  # OAuth::AccessTokenRequest
    ],
});
