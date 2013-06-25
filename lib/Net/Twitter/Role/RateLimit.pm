package Net::Twitter::Role::RateLimit;
use Moose::Role;
use namespace::autoclean;
use Try::Tiny;

requires qw/ua rate_limit_status/;


has _rate_limit_status => (
    isa      => 'HashRef',
    is       => 'rw',
    init_arg => undef,
    lazy     => 1,
    default  => sub { {} },
);

sub _uri_to_resource {
    my $self = shift;
    shift =~ /1\.1(.*)\.json$/;

    $1
}

sub _check_rate {
    my $self = shift;
    my $res  = shift;
    $self->rate_reset($res);
     
    $self->_rate_limit($res)->{remaining}
}

around _json_request => sub {
    my $orig = shift;
    my ($self, $http_method, $uri, $args, $authenticate, $dt_parser, $dblenc, $resource) = @_;
    $resource ||= $self->_uri_to_resource($uri);
    die "cannot call $resource, rate limited" 
        if $resource ne 'application/rate_limit_status' && !$self->_check_rate($resource);

    my $r = $self->$orig($http_method, $uri, $args, $authenticate, $dt_parser, $dblenc, $resource)
};

before _parse_result => sub {
    my ($self, $res, $args, $datetime_parser, $resource) = @_;
    $resource ||= $self->_uri_to_resource($res->uri);
    my @values = map { $res->header('x-rate-limit-'.$_) } qw/remaining reset limit/;
    return unless @values == 3;
    my $values; @{$values}{qw/remaining reset limit/} = @values;

    $self->_rate_limit($resource,$values)
};

around rate_limit_status => sub {
    my $orig = shift;
    my $self = shift;

    my $r = $self->$orig(@_) || return;
    $self->_rate_limit_status($r);

    return $r;
};

sub rate_reset {
    my $self = shift;
    my $res  = shift;
    my $rate = $self->_rate_limit($res);
    $self->rate_limit_status if !$self->_rate_limit_status or !$rate or $rate->{reset} < time;

    $self->_rate_limit($res)->{reset}
}

sub _rate_limit { 
    my $self = shift;
    my $rl   = $self->_rate_limit_status;
    my $res  = shift or return $rl;
    my $val  = shift;
    $res =~ /([^\/]+)/;
    $rl->{resources}{$1}{'/'.$res} = $val if $val;

    $rl->{resources}{$1}{'/'.$res}
}

sub rate_limit {
    my $self = shift;
    my $res  = shift;
    $self->rate_reset($res);
    $self->_rate_limit($res) or die "cannot find this resource: $res"
}

sub rate_ratio {
    my $self = shift;
    my $rate = $self->rate_limit(shift);

    my $full_rate = $rate->{limit} / 15*60;
    my $current_rate = try { $rate->{remaining} / ($rate->{reset} - time) } || 0;
    return $current_rate / $full_rate;
}

sub until_rate {
    my ( $self, $target_rate, $res ) = @_;
    my $rate = $self->rate_limit($res);

    my $s = $rate->{reset} - time - 15*60 * $rate->{remaining} / $target_rate / $rate->{limit};
    return $s > 0 ? $s : 0;
};

1;
