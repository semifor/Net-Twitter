package Net::Twitter;
use Moose;
use Carp;
use Net::Twitter::Core;

use namespace::autoclean;

has '_trait_namespace' => ( default => 'Net::Twitter::Role' );

# use *all* digits for fBSD ports
our $VERSION = '3.03000';

$VERSION = eval $VERSION; # numify for warning-free dev releases

# See Net/Twitter.pod for documentation, Net/Twitter/Core.pm for implementation.
#
# For transparent back compat, Net::Twitter->new() creates a Net::Twitter::Core
# with the 'Legacy' trait.

my $transform_trait = sub {
    my ($class, $name) = @_;
    my $namespace = $class->meta->find_attribute_by_name('_trait_namespace');
    my $base;
    if($namespace->has_default){
        $base = $namespace->default;
        if(ref $base eq 'CODE'){
            $base = $base->();
        }
    }

    return $name unless $base;
    return $1 if $name =~ /^[+](.+)$/;
    return join '::', $base, $name;
};

my $resolve_traits = sub {
    my ($class, @traits) = @_;
    return map {
        my $transformed = $class->$transform_trait($_);
        Class::MOP::load_class($transformed);
        $transformed;
    } @traits;
};

my %ANON_CLASSES;

sub _create_anon_class {
    my ($superclasses, $traits, $immutable) = @_;

    my $cache_key = join '=' => join('|', @$superclasses), join('|', sort @$traits);
    $ANON_CLASSES{$cache_key} ||= do {
        my $meta = Net::Twitter::Core->meta->create_anon_class(
            superclasses => $superclasses,
            roles        => $traits,
            cache        => 1,
        );
        $meta->add_method(meta => sub { $meta });
        $meta->make_immutable if $immutable;
        $meta;
    };
}

sub new {
    my $class = shift;

    croak '"new" is not an instance method' if ref $class;

    my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my $traits = delete $args{traits};

    if ( defined (my $legacy = delete $args{legacy}) ) {
        croak "Options 'legacy' and 'traits' are mutually exclusive. Use only one."
            if $traits;

        $traits = $legacy ? [qw/Legacy/] : [qw/API::REST/];
    }

    $traits ||= [qw/Legacy/];
    $traits = [ $class->$resolve_traits(@$traits) ];

    my $superclasses = [ 'Net::Twitter::Core' ];
    my $meta = _create_anon_class($superclasses, $traits, 1);

    # create a Net::Twitter::Core object
    my $new = $meta->name->new(%args);

    # rebless it to a subclass, if necessary
    unshift @$superclasses, $class if $class ne __PACKAGE__;
    my $final_meta = _create_anon_class($superclasses, $traits, 0);
    bless $new, $final_meta->name if $meta->name ne $final_meta->name;

    return $new;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
