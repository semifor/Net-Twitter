package Net::Twitter::Lite::Search;
use 5.008;
use Moose;
use Carp;
use aliased 'Net::Twitter::Lite::API::Search' => 'API';
use Net::Twitter::Lite;

my $version = Net::Twitter::Lite->VERSION;

has useragent_class => ( isa => 'Str', is => 'ro', default => 'LWP::UserAgent' );
has useragent       => ( isa => 'Str', is => 'ro', default => __PACKAGE__ . "/$version" );
has apiurl          => ( isa => 'Str', is => 'ro', default => API->base_url );
has _ua             => ( isa => 'Object', is => 'rw' );

sub BUILD {
    my $self = shift;

    eval "use " . $self->useragent_class;
    croak $@ if $@;

    my $ua = $self->_ua($self->useragent_class->new);
}

my $method_defs = API->method_definitions;
while ( my ($method, $def) = each %$method_defs ) {
    my ($arg_names, $path) = @{$def}{qw/required path/};

    my $code = sub {
        my $self = shift;

        my $args = {};
        if ( ref $_[0] ) {
            UNIVERSAL::isa($_[0], 'HASH') && @_ == 1 || croak "$method expected a single HASH ref argument";
            $args = { %{shift()} }; # copy callers args since we may add ->{source}
        }
        elsif ( @_ ) {
            @_ == @$arg_names || croak "$method expected @{[ scalar @$arg_names ]} args";
            @{$args}{@$arg_names} = @_;
        }

        my $uri = URI->new($self->apiurl . "/$path.json");
        $uri->query_form($args);

        my $res = $self->_ua->get($uri);
        my $obj = eval { JSON::Any->from_json($res->content) };

        return $obj if $res->is_success && $obj;
        TwitterException->throw(
            error         => $obj->{error},
            http_response => $res,
            twitter_error => $obj
        ) if $obj;
        HttpException->throw(
            error         => $res->message,
            http_response => $res,
        );
    };

    __PACKAGE__->meta->add_method($_, $code) for ( $method, @{$def->{aliases} || []});
}

__PACKAGE__->meta->make_immutable;

1;
