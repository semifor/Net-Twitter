#!/usr/bin/perl
use warnings;
use strict;
use Template;
use lib qw(lib);
use Net::Twitter;

my ($version, $input, $output) = @ARGV;

my $tt = Template->new;
$tt->process($input, {
        VERSION => $version,
        get_methods_for => \&get_methods_for,
    },
    $output,
) || die $tt->error;

sub get_methods_for {
    my $role = shift;

    my $nt = Net::Twitter->new(traits => [$role]);

    return 
        sort { $a->name cmp $b->name }
        grep {
            blessed $_  && $_->isa('Net::Twitter::Meta::Method')
        } $nt->meta->get_all_methods;
}

exit 0;
