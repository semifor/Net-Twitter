#!perl
use warnings;
use strict;
use Test::More;
use List::Util qw/sum/;

use lib qw(t/lib);

eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required for tests' if $@;

use Net::Twitter;
my $nt = Net::Twitter->new(
    ssl    => 0,
    traits => [qw/API::REST API::Search API::TwitterVision/],
    username => 'me', password => 'secret',
);
my $t  = TestUA->new(1, $nt->ua);
my @params = qw/one two three four five/;

my @api_methods =
    grep { blessed $_  && $_->isa('Net::Twitter::Meta::Method') }
    $nt->meta->get_all_methods;

plan tests => 6 * 2 * sum map 1 + @{$_->aliases}, @api_methods;

# 2 passes to ensure nothing on the first pass changes internal state affecting the 2nd
for my $pass ( 1, 2 ) {
    for my $entry ( sort { $a->name cmp $b->name } @api_methods ) {
        my $pos_params  = $entry->required;
        my $path        = $entry->path;

        $pos_params = $entry->params if @$pos_params == 0 && @{$entry->params} == 1;

        my @named_params = $path =~ /:(\w+)/g;
        for ( my $i = 0; $i < @named_params; ++$i ) {
            $path =~ s/:$named_params[$i]/$params[$i]/;
        }

        @$pos_params = @named_params;

        $path = "/$path.json";

        for my $call ( $entry->name, @{$entry->aliases} ) {
            # the parameter names/values expected in GET/POST parameters
            my %expected;
            my @local_params = @params[0..$#{$pos_params}];
            @expected{@$pos_params} = @local_params;

            # HACK! Expect "true" or "false" for boolean params
            for my $bool_param ( @{ $entry->booleans || [] } ) {
                if ( exists $expected{$bool_param} ) {
                    $expected{$bool_param} = $expected{$bool_param} ? 'true' : 'false';
                }
            }

            $expected{source} = $nt->source if $entry->add_source;

            my $r = eval { $nt->$call(@local_params) };
            diag "$@\n" if $@;
            ok $r,                          "[$pass] $call(@{[ join ', ' => @$pos_params ]})";

            my $args = $t->args;

            {
                my $expected_count = 0;
                my $got_count      = 0;
                for ( my $i = 0; $i < @named_params; ++$i ) {
                    delete $expected{$named_params[$i]} && ++$expected_count;
                    $t->path =~ m{/$params[$i] [/.]}x  && ++$got_count;
                }
                is $got_count, $expected_count,      "[$pass] got expected named params";
                is $got_count, scalar @named_params, "[$pass] named params count";
            }

            is_deeply $args, \%expected,    "[$pass] $call args";
            is $t->path, $path,             "[$pass] $call path";
            is $t->method, $entry->method,  "[$pass] $call method";
        }
    }
}

exit 0;
