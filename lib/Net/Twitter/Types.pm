package Net::Twitter::Types;

use Moose::Util::TypeConstraints;
use URI;

class_type 'Net::Twitter::Types::URI', { class => 'URI' };

coerce 'Net::Twitter::Types::URI' => from 'Str' => via { URI->new($_) };

1;

__END__

=pod

=head1 NAME

Net::Twitter::Types - types and coercions for Net::Twitter

=cut
