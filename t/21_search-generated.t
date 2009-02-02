#!perl
use warnings;
use strict;
use Test::More;
use aliased 'Net::Twitter::Lite::Search';
use aliased 'Net::Twitter::Lite::API::Search' => 'API';
use List::Util qw/sum/;

use lib qw(t/lib);

use Mock::LWP::UserAgent;

my $nt     = Search->new;
my $ua     = $nt->_ua;
$ua->_host('search.twitter.com');
my @params = qw/twitter_id another_id/;

plan tests => 4 * 2 * sum map 1 + @{$_->[1]{aliases}||[]}, map @{$_->[1]}, @{API->definition};

# 2 passes to ensure nothing on the first pass changes internal state affecting the 2nd
for my $pass ( 1, 2 ) {
    for my $entry ( map @{$_->[1]}, @{API->definition} ) {
        my ($api_method, $def) = @$entry;
        my ($aliases, $required, $method, $path) = @{$def}{qw/aliases required method path/};

        my $has_id = $path =~ s,/id,/$params[0],;
        $path = "/$path.json";

        for my $call ( $api_method, @{$aliases || []} ) {
            # the parameter names/values expected in GET/POST parameters
            my %expected;
            my @local_params = @params[0..$#{$required}];
            @expected{@$required} = @local_params;
            $expected{source} = $nt->source if $api_method eq 'update';

            ok $nt->$call(@local_params),          "[$pass] $call(@{[ join ', ' => @$required ]})";
            is_deeply $ua->input_args, \%expected, "[$pass] $call args";
            is $ua->input_uri->path, $path,        "[$pass] $call path";
            is $ua->input_method, $method,         "[$pass] $call method";
        }
    }
}

exit 0;
