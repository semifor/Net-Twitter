package Net::Twitter::Identica;
use Net::Twitter;

sub new { shift; Net::Twitter->new(identica => 1, @_) }

1;
