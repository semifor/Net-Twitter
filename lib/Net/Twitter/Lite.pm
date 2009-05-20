package Net::Twitter::Lite;
use Moose;
extends 'Net::Twitter::Lite::Base';

use namespace::autoclean;

with 'Net::Twitter::Lite::API::REST';

__PACKAGE__->meta->make_immutable;

1;
