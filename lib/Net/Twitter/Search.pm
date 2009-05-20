package Net::Twitter::Search;
use Moose;
extends 'Net::Twitter::Base';

use namespace::autoclean;

with 'Net::Twitter::API::Search';

__PACKAGE__->meta->make_immutable;

1;
