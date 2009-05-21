package Net::Twitter::Identica;
use Moose;
extends 'Net::Twitter';

use namespace::autoclean;

with 'Net::Twitter::API::REST';

has '+apiurl'   => ( default => 'http://identi.ca/api' );
has '+apihost'  => ( default => 'identi.ca:80' );
has '+apirealm' => ( default => 'Laconica API' );

__PACKAGE__->meta->make_immutable;

1;
