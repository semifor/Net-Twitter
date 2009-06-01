package Net::Twitter;
use warnings;
use strict;
use Carp;
use Net::Twitter::Core;

# use *all* digits for fBSD ports
our $VERSION = '3.00002';

$VERSION = eval $VERSION; # numify for warning-free dev releases

# See Net/Twitter.pod for documentation, Net/Twitter/Core.pm for implementation.
#
# For transparent back compat, Net::Twitter->new() creates a Net::Twitter::Core
# with the 'Legacy' trait.

sub new {
    my $class = shift;
    my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my $traits = delete $args{traits};

    if ( defined (my $legacy = delete $args{legacy}) ) {
        croak "Options 'legacy' and 'traits' are mutually exclusive. Use only one."
            if $traits;

        $traits = $legacy ? [qw/Legacy/] : [qw/API::REST/];
    }

    $traits ||= [qw/Legacy/];
    return Net::Twitter::Core->new_with_traits(traits => $traits, %args);
}

1;
