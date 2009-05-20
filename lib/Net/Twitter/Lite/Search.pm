package Net::Twitter::Lite::Search;
use Moose;
extends 'Net::Twitter::Lite::Base';

use namespace::autoclean;

with 'Net::Twitter::Lite::API::Search';

__PACKAGE__->meta->make_immutable;

1;
