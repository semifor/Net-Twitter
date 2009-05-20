package Net::Twitter::REST;
use Moose;
extends 'Net::Twitter::Base';

use namespace::autoclean;

with 'Net::Twitter::API::REST';

__PACKAGE__->meta->make_immutable;

1;
