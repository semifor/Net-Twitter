#!/usr/bin/perl
#
# Net::Twitter - OAuth desktop app example
#
use warnings;
use strict;

use Net::Twitter;
use File::Spec;
use Storable;
use Data::Dumper;

# You can replace the consumer tokens with your own;
# these tokens are for the Net::Twitter example app.
my %consumer_tokens = (
    consumer_key    => 'v8t3JILkStylbgnxGLOQ',
    consumer_secret => '5r31rSMc0NPtBpHcK8MvnCLg2oAyFLx5eGOMkXM',
);

# $datafile = oauth_desktop.dat
my (undef, undef, $datafile) = File::Spec->splitpath($0);
$datafile =~ s/\..*/.dat/;

my $nt = Net::Twitter->new(traits => [qw/API::RESTv1_1/], %consumer_tokens);
my $access_tokens = eval { retrieve($datafile) } || [];

if ( @$access_tokens ) {
    $nt->access_token($access_tokens->[0]);
    $nt->access_token_secret($access_tokens->[1]);
}
else {
    my $auth_url = $nt->get_authorization_url;
    print " Authorize this application at: $auth_url\nThen, enter the PIN# provided to contunie: ";

    my $pin = <STDIN>; # wait for input
    chomp $pin;

    # request_access_token stores the tokens in $nt AND returns them
    my @access_tokens = $nt->request_access_token(verifier => $pin);

    # save the access tokens
    store \@access_tokens, $datafile;
}

my $status = $nt->user_timeline({ count => 1 });
print Dumper $status;
