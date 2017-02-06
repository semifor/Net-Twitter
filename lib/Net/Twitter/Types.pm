package Net::Twitter::Types;
use Moose::Util::TypeConstraints;
use URI;

class_type 'URI';

coerce URI => from 'Str' => via { URI->new($_) };

1;
