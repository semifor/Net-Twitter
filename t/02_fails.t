#!perl
use warnings;
use strict;
use Test::More;
use Test::Fatal;
use lib qw(t/lib);
use Net::Twitter;

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required for tests' if $@;

plan tests => 2;

my $nt = Net::Twitter->new(
    ssl      => 0,
    traits   => [qw/API::REST/],
    username => 'just_me',
    password => 'secret',
);

my $t = TestUA->new(1, $nt->ua);

# things that should fail
like exception { $nt->relationship_exists(qw/one two three/) }, qr/expected 2 args/, 'too many args';
like exception { Net::Twitter->new(ssl => 0, useragent_class => 'NoSuchModule::Test7701')->verify_credentials },
     qr/Can't locate NoSuchModule/, 'bad useragent_class';

exit 0;
