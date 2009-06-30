#!perl
use warnings;
use strict;
use Test::More tests => 27;

{
    package My::Subclass::WithNew;
    use base qw/Net::Twitter/;

    sub new {
        my $class = shift;

        my $new = $class->SUPER::new(@_);
        $new->{subclass_attribute} = 'attribute value';

        return $new;
    }

    sub subclass_method { shift->{subclass_attribute} }
}

{
    package My::Subclass::WithoutNew;
    use base qw/Net::Twitter/;

    sub subclass_method {
        my $self = shift;

        $self->{subclass_attribute} = shift if @_;
        return $self->{subclass_attribute};
    }
}

{
    package My::Subclass::WithMoose;
    use Moose;
    extends 'Net::Twitter';

    has subclass_attribute => ( is => 'rw', default => 'attribute value' );

    sub subclass_method { shift->subclass_attribute(@_) }
}

{
    package My::Subclass::ValidMoose;
    use Moose;
    extends 'Net::Twitter::Core';

    with 'Net::Twitter::Role::API::REST';

    has subclass_attribute => ( reader => 'subclass_method', default => 'attribute value' );
}

diag 'subclass with new';
my $nt1 = My::Subclass::WithNew->new(username => 'me', password => 'secret');
isa_ok  $nt1, 'Net::Twitter';
isa_ok  $nt1, 'Net::Twitter::Core';
isa_ok  $nt1, 'My::Subclass::WithNew';
can_ok  $nt1, qw/subclass_method user_timeline search credentials/;
is      $nt1->subclass_method, 'attribute value', 'has subclass attribute value';
is      $nt1->password, 'secret', 'has base class attribute value';

diag 'subclass without new';
my $nt2 = My::Subclass::WithoutNew->new(username => 'me', password => 'secret');
isa_ok  $nt2, 'Net::Twitter';
isa_ok  $nt2, 'Net::Twitter::Core';
isa_ok  $nt2, 'My::Subclass::WithoutNew';
can_ok  $nt2, qw/subclass_method user_timeline search credentials/;
is      $nt2->subclass_method('test'), 'test', 'has subclass attribute value';
is      $nt2->password, 'secret', 'has base class attribute value';

TODO: {
local $TODO = 'Moose classes should subclass Core, not Net::Twitter';
diag 'Moose subclass';
my $nt3 = My::Subclass::WithMoose->new(username => 'me', password => 'secret');
isa_ok  $nt3, 'Net::Twitter';
isa_ok  $nt3, 'Net::Twitter::Core';
isa_ok  $nt3, 'My::Subclass::WithMoose';
can_ok  $nt3, qw/subclass_method user_timeline search credentials/;
is      $nt3->subclass_method, 'attribute value', 'has subclass attribute value';
is      $nt3->password, 'secret', 'has base class attribute value';
}

diag 'valid Moose subclass';
my $nt4 = My::Subclass::ValidMoose->new(username => 'me', password => 'secret');
ok      !$nt4->isa('Net::Twitter'), 'not created by Net::Twitter';
isa_ok  $nt4, 'Net::Twitter::Core';
isa_ok  $nt4, 'My::Subclass::ValidMoose';
can_ok  $nt4, qw/subclass_method user_timeline credentials/;
is      $nt4->subclass_method, 'attribute value', 'has subclass attribute value';
is      $nt4->password, 'secret', 'has base class attribute value';

diag 'class reuse';
is      ref $nt1, ref My::Subclass::WithNew->new, 'reused anon class';
ok      ref $nt1 ne ref $nt2, 'different subclasses have different anon classes';
ok      ref $nt1 ne ref My::Subclass::WithNew->new(legacy => 0), 'different roles have different classes';
