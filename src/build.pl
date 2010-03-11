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
            $_->isa('Net::Twitter::Meta::Method')
        }
        map {
            $_->isa('Class::MOP::Method::Wrapped') ? $_->get_original_method : $_
        } $nt->meta->get_all_methods;
}

exit 0;
