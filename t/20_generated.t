#!perl
use warnings;
use strict;
use Test::More;
use List::Util qw/sum/;

use lib qw(t/lib);

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required for tests' if $@;

use Net::Twitter;
my $nt = Net::Twitter->new(traits => [qw/API::REST API::Search API::TwitterVision/]);
my $t  = TestUA->new($nt->ua);
my @params = qw/twitter_id another_id/;

my @api_methods =
    grep { blessed $_  && $_->isa('Net::Twitter::Meta::Method') }
    $nt->meta->get_all_methods;

plan tests => 5 * 2 * sum map 1 + @{$_->aliases}, @api_methods;

# 2 passes to ensure nothing on the first pass changes internal state affecting the 2nd
for my $pass ( 1, 2 ) {
    for my $entry ( sort { $a->name cmp $b->name } @api_methods ) {
        my $pos_params  = $entry->required;
        my $path        = $entry->path;

        $pos_params = $entry->params if @$pos_params == 0 && @{$entry->params} == 1;

        my $has_id = $path =~ s|/id$|/$params[0]|;
        if ( $has_id && @$pos_params == 0 ) {
            @$pos_params = 'id';
        }

        $path = "/$path.json";

        for my $call ( $entry->name, @{$entry->aliases} ) {
            # the parameter names/values expected in GET/POST parameters
            my %expected;
            my @local_params = @params[0..$#{$pos_params}];
            @expected{@$pos_params} = @local_params;
            $expected{source} = $nt->source if $entry->add_source;

            my $r = eval { $nt->$call(@local_params) };
            diag "$@\n" if $@;
            ok $r,                          "[$pass] $call(@{[ join ', ' => @$pos_params ]})";

            # horrible kludge
            my $args = $t->args;
            ok !$has_id || (
                    delete $expected{id} &&
                    $t->path =~ /\/twitter_id\.json/
                ), "id test";

            is_deeply $args, \%expected,    "[$pass] $call args";
            is $t->path, $path,             "[$pass] $call path";
            is $t->method, $entry->method,  "[$pass] $call method";
        }
    }
}

exit 0;
