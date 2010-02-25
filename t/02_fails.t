#!perl
use warnings;
use strict;
use Test::More;
use Test::Exception;
use lib qw(t/lib);
use Net::Twitter;

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required for tests' if $@;

plan tests => 2;

my $nt = Net::Twitter->new(
    traits   => [qw/API::REST/],
    username => 'just_me',
    password => 'secret',
);

my $t = TestUA->new($nt->ua);

# things that should fail
throws_ok { $nt->relationship_exists(qw/one two three/) } qr/expected 2 args/, 'too many args';
throws_ok {
    Net::Twitter->new(useragent_class => 'NoSuchModule::Test7701')->verify_credentials
} qr/Can't locate NoSuchModule/, 'bad useragent_class';
        qr/must not be a reference/, 'extra args';

exit 0;
