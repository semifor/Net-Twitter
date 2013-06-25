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

# #CONFIGURATION Remove "#" for Smart::Comments
# use Smart::Comments;

# TODO Refactor with Getopt::Long CPAN Module
# https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline
# #CONFIGURATION $screen_name is https://twitter.com/[INSERT screen_name]
my $screen_name = "cmlh";

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

# my $ua = $nt->ua;
# 127.0.0.1:8080 for http://portswigger.net/burp/help/proxy_using.html
# $ua->proxy(['http', 'https'] => 'http://127.0.0.1:8080');

my $access_tokens = eval { retrieve($datafile) } || [];

if ( @$access_tokens ) {
    $nt->access_token($access_tokens->[0]);
    $nt->access_token_secret($access_tokens->[1]);
}
else {
    my $auth_url = $nt->get_authorization_url;
    print "\n1. Authorize the Twitter App at: $auth_url\n2. Enter the returned PIN to complete the Twitter App authorization process: ";

    my $pin = <STDIN>; # wait for input
    chomp $pin;
    print "\n";

    # request_access_token stores the tokens in $nt AND returns them
    my @access_tokens = $nt->request_access_token(verifier => $pin);

    # save the access tokens
    store \@access_tokens, $datafile;
}

my $statuses_ref = $nt->user_timeline({ count => 1, screen_name => $screen_name });
# print Dumper $statuses_ref;
print "\n";

my @statuses = @{$statuses_ref};
my $statuses_count = $statuses[0]->{user}{statuses_count};

# "###" is for Smart::Comments CPAN Module
### \$statuses_count is: $statuses_count

# "...return up to 3,200 of a user's most recent Tweets." quoted from https://dev.twitter.com/docs/api/1.1/get/statuses/user_timeline
my $twitter_api_v1_1_tweet_total = 3200;

if ($statuses_count > $twitter_api_v1_1_tweet_total) {
	# "###" is for Smart::Comments CPAN Module
	### Reduced \$statuses_count to 3200
	$statuses_count = $twitter_api_v1_1_tweet_total;
}

# "###" is for Smart::Comments CPAN Module
### \$statuses_count is: $statuses_count

my $max_id = $statuses[0]->{id_str};

# "####" is for Smart::Comments CPAN Module
#### \$max_id is: $max_id

print "\n";

my $count = 200;

open (TIMELINE_DUMPER, ">>", "$screen_name" . "_dumper.txt");

# Timeline is less than 200 tweets
if ($statuses_count >= $count) {
	while ($statuses_count > $count) {
		# TODO Refactor as sub()
		$statuses_ref = $nt->user_timeline({ count => $count, max_id => $max_id, screen_name => $screen_name });
		# print Dumper $statuses_ref;
		print TIMELINE_DUMPER (Data::Dumper::Dumper($statuses_ref));
		foreach my $status (@$statuses_ref) {
			$max_id = $status->{id_str};
			# "####" is for Smart::Comments CPAN Module
			#### \$max_id is: $max_id
		}
		# "####" is for Smart::Comments CPAN Module
		#### \$max_id is: $max_id
		$statuses_count = $statuses_count - $count; 
		# "###" is for Smart::Comments CPAN Module
		### \$statuses_count is: $statuses_count
	}
}

if ($statuses_count != 0) {
	# TODO Refactor as sub()
	# "###" is for Smart::Comments CPAN Module
	### \$count is: $count
	$statuses_ref = $nt->user_timeline({ count => $count, max_id => $max_id, screen_name => $screen_name });
	# print Dumper $statuses_ref;
	print TIMELINE_DUMPER (Data::Dumper::Dumper($statuses_ref));
	foreach my $status (@$statuses_ref) {
		$max_id = $status->{id_str};
		# "####" is for Smart::Comments CPAN Module
		#### \$max_id is: $max_id
	}
	# "####" is for Smart::Comments CPAN Module
	#### \$max_id is: $max_id
	$statuses_count = $statuses_count - $count; 
	# "###" is for Smart::Comments CPAN Module
	### \$statuses_count is: $statuses_count
}
