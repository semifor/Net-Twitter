package Net::Twitter::Search;
use Moose;
extends 'Net::Twitter';

use namespace::autoclean;

__PACKAGE__->meta->make_immutable;
# Net::Twitter::Search was really just an alias for legacy Net::Twitter
# Deprecated.
#
# Suggest:
#
#   $nt = Net::Twitter->new(traits => [qw/API::Search/]);
#
# Or, for code that relies on the legacy Net::Twitter error handling:
#
#   $nt = Net::Twitter->new(traits => [qw/API::Search WrapError/]);
#
# For code that relied on other API methods:
#
#   $nt = Net::Twitter->new(traits => [qw/Legacy/]);
#

1;
