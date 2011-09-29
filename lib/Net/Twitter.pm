package Net::Twitter;
use Moose;
use Carp;
use JSON;
use Net::Twitter::Core;
use Digest::SHA qw/sha1_hex/;

use namespace::autoclean;

has '_trait_namespace' => (
    Moose->VERSION >= '0.85' ? (is => 'bare') : (),
    default => 'Net::Twitter::Role',
);

# use *all* digits for fBSD ports
our $VERSION = '3.18001';

$VERSION = eval $VERSION; # numify for warning-free dev releases

# See Net/Twitter.pod for documentation, Net/Twitter/Core.pm for implementation.
#
# For transparent back compat, Net::Twitter->new() creates a Net::Twitter::Core
# with the 'Legacy' trait.

# transform_trait and resolve_traits stolen from MooseX::Traits
sub _transform_trait {
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
    return "$base\::$name";
}

sub _resolve_traits {
    my ($class, @traits) = @_;

    return map {
        unless ( ref ) {
            $_ = $class->_transform_trait($_);
            Class::MOP::load_class($_);
        }
        $_;
    } @traits;
}

sub _isa {
    my $self = shift;
    my $isa  = shift;

    return $isa eq __PACKAGE__ || $self->SUPER::isa($isa)
};

sub _create_anon_class {
    my ($superclasses, $traits, $immutable, $package) = @_;

    # Do we already have a meta class?
    return $package->meta if $package->can('meta');

    my $meta;
    $meta = Net::Twitter::Core->meta->create_anon_class(
        superclasses => $superclasses,
        roles        => $traits,
        methods      => { meta => sub { $meta }, isa => \&_isa },
        cache        => 0,
        package      => $package,
    );
    $meta->make_immutable(inline_constructor => $immutable);

    return $meta;
}

{
    my $serial_number = 0;
    my %serial_for_params;

    sub _name_for_anon_class {
        my @t = @{$_[0]};

        my @comps;
        while ( @t ) {
            my $t = shift @t;
            if ( ref $t[0] eq 'HASH' ) {
                my $params = shift @t;
                my $sig = sha1_hex(JSON->new->utf8->encode($params));
                my $sn  = $serial_for_params{$sig} ||= ++$serial_number;
                $t .= "_$sn";
            }
            $t =~ s/(?:::|\W)/_/g;
            push @comps, $t;
        }

        my $ver = $VERSION;
        $ver =~ s/\W/_/g;

        return __PACKAGE__ . "_v${ver}_" .  join '__', 'with', sort @comps;
    }
}

sub new {
    my $class = shift;

    croak '"new" is not an instance method' if ref $class;

    my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{$_[0]} : @_;

    my $traits = delete $args{traits};

    if ( defined (my $legacy = delete $args{legacy}) ) {
        croak "Options 'legacy' and 'traits' are mutually exclusive. Use only one."
            if $traits;

        $traits = [ $legacy ? 'Legacy' : 'API::REST' ];
    }

    $traits ||= [ qw/Legacy/ ];

    # ensure we have the OAuth trait if we have a consumer key
    $traits = [ (grep $_ ne 'OAuth', @$traits), 'OAuth' ] if $args{consumer_key};

    # create a unique name for the created class based on trait names and parameters
    my $anon_class_name = _name_for_anon_class($traits);

    $traits = [ $class->_resolve_traits(@$traits) ];

    my $superclasses = [ 'Net::Twitter::Core' ];
    my $meta = _create_anon_class($superclasses, $traits, 1, $anon_class_name);

    # create a Net::Twitter::Core object with roles applied
    my $new = $meta->name->new(%args);

    # rebless it to include a superclass, if we're being subclassed
    if ( $class ne __PACKAGE__ ) {
        unshift @$superclasses, $class;
        my $final_meta = _create_anon_class(
            $superclasses, $traits, 0, join '::', $class, $anon_class_name
        );
        bless $new, $final_meta->name;
    }

    return $new;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
