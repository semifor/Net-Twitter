#!perl -w
use strict;
use warnings;
use Test::More;

plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};

eval 'use Test::Spelling 0.11';
plan skip_all => 'Test::Spelling 0.11 not installed' if $@;

set_spell_cmd('aspell list');

add_stopwords(<DATA>);

all_pod_files_spelling_ok();

__DATA__
API
JSON
Marc
Mims
Twitter
