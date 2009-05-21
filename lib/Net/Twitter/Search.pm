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
#   use Net::Twitter qw/API::Search/;
#
# Or, for code that relies on the legacy Net::Twitter error handling:
#
#   use Net::Twitter qw/API::Search WrapError/;
#
# For code that relied on other API methods:
#
#   use Net::Twitter qw/Legacy/;
#

1;
