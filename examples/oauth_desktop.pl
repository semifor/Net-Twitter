#!/usr/bin/env perl
# The above shebang is for "perlbrew", otherwise use /usr/bin/perl or the file path quoted for "which perl"
#
# Please refer to the Plain Old Documentation (POD) at the end of this Perl Script for further information

use warnings;
use strict;
use Net::Twitter;
use Pod::Usage;
use File::Spec;
use Storable;
use Getopt::Long;
use Data::Dumper;
use YAML::XS;    # TODO Refactor with YAML::Tiny

# use utf8; applied within YAML::XS
# TODO use JSON;

# #CONFIGURATION Remove "#" for Smart::Comments
# use Smart::Comments '####','###';
# TODO Refactor Smart::Comments -ENV i.e. http://search.cpan.org/~dconway/Smart-Comments-1.000005/lib/Smart/Comments.pm#CONFIGURATION_AND_ENVIRONMENT

# "####" is for Smart::Comments CPAN Module
#### [<time>] oauth_desktop.pl start

my $VERSION = "0.001_3";
$VERSION = eval $VERSION;

print "\n\"oauth_desktop\" Alpha v$VERSION\n";
print "\n";
print "Copyright 2013, 2014 Christian Heinrich and Marc Mims\n";
print "Licensed under the Apache License, Version 2.0\n\n";

# Command line arguements
my $screen_name = "cmlh";
# TODO since_id i.e. https://dev.twitter.com/docs/working-with-timelines

# Command line meta-options
my $usage  = 0;
my $man    = 0;
my $update = 0;

# TODO Display -usage if command line argument(s) are incorrect
GetOptions(

    # https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline
    "screen_name=s" => \$screen_name,

# Command line meta-options
# -version is excluded as it is printed prior to processing the command line arguments
# TODO -verbose
    "usage"  => \$usage,
    "man"    => \$man,
    "update" => \$update
);

if ( ( $usage eq 1 ) or ( $man eq 1 ) ) {
    pod2usage( -verbose => 2 );
    die();
}

if ( $update eq 1 ) {
    print
"Please execute \"git fetch git://github.com/cmlh/Net-Twitter.git\" from the command line\n";
    die();
}

# TODO Confirm that -screen_name does exist on Twitter
# TODO insert $statuses_count i.e. $statuses[0]->{user}{statuses_count}
print "Retrieving $screen_name tweets.\n\n";

# "####" is for Smart::Comments CPAN Module
#### \$screen_name is: $screen_name;

# You can replace the consumer tokens with your own;
# these tokens are for the Net::Twitter example app.
my %consumer_tokens = (
    consumer_key    => 'v8t3JILkStylbgnxGLOQ',
    consumer_secret => '5r31rSMc0NPtBpHcK8MvnCLg2oAyFLx5eGOMkXM',
);

# $datafile = oauth_desktop.dat
my ( undef, undef, $datafile ) = File::Spec->splitpath($0);
$datafile =~ s/\..*/.dat/;

my $nt = Net::Twitter->new( traits => [qw/API::RESTv1_1/], %consumer_tokens, ssl => 1, );

# my $ua = $nt->ua;
# 127.0.0.1:8080 for http://portswigger.net/burp/help/proxy_using.html
# $ua->proxy(['http', 'https'] => 'http://127.0.0.1:8080');

my $access_tokens = eval { retrieve($datafile) } || [];

if (@$access_tokens) {
    $nt->access_token( $access_tokens->[0] );
    $nt->access_token_secret( $access_tokens->[1] );
}
else {
    my $auth_url = $nt->get_authorization_url;
    print
"\n1. Authorize the Twitter App at: $auth_url\n2. Enter the returned PIN to complete the Twitter App authorization process: ";

    my $pin = <STDIN>;    # wait for input
    chomp $pin;
    print "\n";

    # request_access_token stores the tokens in $nt AND returns them
    # TODO Raise an exception if $pin is incorrect
    my @access_tokens = $nt->request_access_token( verifier => $pin );

    # save the access tokens
    store \@access_tokens, $datafile;
}

# TODO https://dev.twitter.com/docs/rate-limiting, has dependency on either
# https://github.com/semifor/Net-Twitter/pull/32 or 
# https://github.com/semifor/Net-Twitter/pull/31
my $statuses_ref =
  $nt->user_timeline( { count => 1, screen_name => $screen_name } );

my @statuses       = @{$statuses_ref};
my $statuses_count = $statuses[0]->{user}{statuses_count};

# "####" is for Smart::Comments CPAN Module
#### \$statuses_count is: $statuses_count

# "...return up to 3,200 of a user's most recent Tweets." quoted from https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline
my $twitter_api_v1_1_tweet_total = 3200;

if ( $statuses_count > $twitter_api_v1_1_tweet_total ) {

    # "###" is for Smart::Comments CPAN Module
    ### Reduced \$statuses_count to 3200
    $statuses_count = $twitter_api_v1_1_tweet_total;
}

# "####" is for Smart::Comments CPAN Module
#### \$statuses_count is: $statuses_count

my $max_id = $statuses[0]->{id_str};

# "####" is for Smart::Comments CPAN Module
#### \$max_id is: $max_id

my $count               = 200;
my $contributor_details = 1;     # true
my $include_rts         = 1;     # true

open( TIMELINE_DATA_DUMPER, ">>", "$screen_name" . "_dumper.txt" );
open( TIMELINE_YAML_DUMPER, ">>", "$screen_name" . "_dumper.yml" );

# Timeline is less than 200 tweets
if ( $statuses_count >= $count ) {

    # TODO Display Progress Bar
    while ( $statuses_count > $count ) {

        # TODO Refactor as sub()
        $statuses_ref = $nt->user_timeline(
            {
                count               => $count,
                max_id              => $max_id,
                screen_name         => $screen_name,
                contributor_details => $contributor_details,
                include_rts         => $include_rts
            }
        );

        @statuses = @{$statuses_ref};

        my $data_dumper = Data::Dumper->new( [ \@statuses ], [qw (statuses)] );
        print TIMELINE_DATA_DUMPER ( $data_dumper->Dump );
        my $yaml_dumper = Dump @statuses;
        print TIMELINE_YAML_DUMPER ($yaml_dumper);
        foreach my $status (@$statuses_ref) {
            $max_id = $status->{id_str};

            # "####" is for Smart::Comments CPAN Module
            #### \$max_id is: $max_id
        }

        # "####" is for Smart::Comments CPAN Module
        #### \$max_id is: $max_id

        $statuses_count = $statuses_count - $count;

        # "####" is for Smart::Comments CPAN Module
        #### \$statuses_count is: $statuses_count
    }
}

if ( $statuses_count != 0 ) {

    # TODO Refactor as sub()
    # "####" is for Smart::Comments CPAN Module
    #### \$count is: $count
    $statuses_ref = $nt->user_timeline(
        {
            count               => $count,
            max_id              => $max_id,
            screen_name         => $screen_name,
            contributor_details => $contributor_details,
            include_rts         => $include_rts
        }
    );

    @statuses = @{$statuses_ref};

    my $data_dumper = Data::Dumper->new( [ \@statuses ], [qw (statuses)] );
    print TIMELINE_DATA_DUMPER ( $data_dumper->Dump );
    my $yaml_dumper = Dump @statuses;
    print TIMELINE_YAML_DUMPER ($yaml_dumper);

    foreach my $status (@$statuses_ref) {
        $max_id = $status->{id_str};

        # "####" is for Smart::Comments CPAN Module
        #### \$max_id is: $max_id
    }

    # "####" is for Smart::Comments CPAN Module
    #### \$max_id is: $max_id
    $statuses_count = $statuses_count - $count;

    # "####" is for Smart::Comments CPAN Module
    #### \$statuses_count is: $statuses_count
}

#### [<time>] oauth_desktop.pl finsh

=head1 NAME

oauth_desktop.pl

=head1 VERSION

This documentation refers to oauth_desktop $VERSION

=head1 CONFIGURATION

Set the value(s) marked as #CONFIGURATION above this POD
    
=head1 USAGE

oauth_desktop.pl [-screen_name] [screen name]

=head1 REQUIRED ARGUEMENTS

=head2 Command Line

-screen_name [screen_name]
                
=head1 OPTIONAL ARGUEMENTS

-man       Displays POD and exits.
-usage     Displays POD and exits.
-update    Displays the git fetch from github.com command.

=head1 DESCRIPTION

"oauth_desktop.pl" leverages the Twitter API v1.1 to archive the last 3200 tweets of a screen name.

Based on "Net::Twitter - OAuth desktop app example" from Marc Mims.

=head1 DEPENDENCIES

=head1 PREREQUISITES

TODO

=head1 COREQUISITES

=head1 INSTALLATION

=head1 OSNAMES

osx

=head1 SCRIPT CATEGORIES

Web

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

Please refer to the comments beginning with "TODO" in the Perl Code.

=head1 AUTHOR

Christian Heinrich
Marc Mims

=head1 CONTACT INFORMATION

http://cmlh.id.au/contact

=head1 MAILING LIST

=head1 REPOSITORY

https://github.com/cmlh/Net-Twitter forked from https://github.com/semifor/Net-Twitter

=head1 FURTHER INFORMATION AND UPDATES

http://del.icio.us/cmlh/Twitter

=head1 LICENSE AND COPYRIGHT

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License. 

Copyright 2013, 2014 Christian Heinrich
