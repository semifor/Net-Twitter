package Net::Twitter::API;
use Moose ();
use Carp;
use Moose::Exporter;
use URI::Escape;

Moose::Exporter->setup_import_methods(
    with_caller => [ 'base_url', 'twitter_api_method' ],
);

my $post_request = sub {
    my ($ua, $uri, $args) = @_;
    return $ua->post($uri, $args);
};

my $get_request = sub {
    my ($ua, $uri, $args) = @_;
    $uri->query_form($args);
    return $ua->get($uri);
};

my $with_url_arg = sub {
    my ($path, $args) = @_;

    if ( defined(my $id = delete $args->{id}) ) {
        $path .= uri_escape($id);
    }
    else {
        chop($path);
    }
    return $path;
};

sub twitter_api_method {
    my ($caller, $name, %options) = @_;

    my $class = Moose::Meta::Class->initialize($caller);

    my ($arg_names, $path) = @options{qw/required path/};
    $arg_names = $options{params} if @$arg_names == 0 && @{$options{params}} == 1;
    my $request = $options{method} eq 'POST' ? $post_request : $get_request;

    my $modify_path = $path =~ s,/id$,/, ? $with_url_arg : sub { $_[0] };

    my $code = sub {
        my $self = shift;

        my $args = {};
        if ( ref $_[0] ) {
            UNIVERSAL::isa($_[0], 'HASH') && @_ == 1 || croak "$name expected a single HASH ref argument";
            $args = { %{shift()} }; # copy callers args since we may add ->{source}
        }
        elsif ( @_ ) {
            @_ == @$arg_names || croak "$name expected @{[ scalar @$arg_names ]} args";
            @{$args}{@$arg_names} = @_;
        }
        $args->{source} ||= $self->source if $options{add_source};

        my $local_path = $modify_path->($path, $args);
        
        my $uri = URI->new($caller->_base_url($self) . "/$local_path.json");
        return $self->_parse_result($request->($self->ua, $uri, $args));
    };

    $class->add_method(
        $name,
        Net::Twitter::Meta::Method->new(
            name => $name,
            package_name => $caller,
            body => $code,
            %options,
        ),
    );

    $class->add_method($_, $code) for @{$options{aliases} || []};
}

sub base_url {
    my ($caller, $name, %options) = @_;
    
    Moose::Meta::Class->initialize($caller)->add_method(_base_url => sub { $_[1]->$name });
}


package Net::Twitter::Meta::Method;
use Moose;
extends 'Moose::Meta::Method';

use namespace::clean;

has description => ( isa => 'Str', is => 'ro', required => 1 );
has aliases     => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] } );
has path        => ( isa => 'Str', is => 'ro', required => 1 );
has method      => ( isa => 'Str', is => 'ro', default => 'GET' );
has add_source  => ( isa => 'Bool', is => 'ro', default => 0 );
has params      => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] } );
has required    => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] } );
has returns     => ( isa => 'Str', is => 'ro', predicate => 'has_returns' );
has deprecated  => ( isa => 'Bool', is => 'ro', default => 0 );

sub new { shift->SUPER::wrap(@_) }

1;
