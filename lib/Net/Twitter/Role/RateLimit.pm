package Net::Twitter::Role::RateLimit;

use Moose::Role;
use namespace::autoclean;
use Try::Tiny;
use Scalar::Util qw/weaken/;

=head1 NAME

Net::Twitter::Role::RateLimit - Rate limit features for Net::Twitter

=head1 SYNOPSIS

    use Net::Twitter;
    my $nt = Net::Twitter->new(
        traits => [qw/API::REST RateLimit/],
        %other_options,
    );

    #...later

    sleep $nt->until_rate(1.0) || $minimum_wait;

=head1 NOTE!

RateLimit only works with Twitter API v1. The rate limiting strategy of Twitter
API v1.1 is very different. A v1.1 compatible RateLimit role may be coming, but
isn't available, yet. It's interface will necessarily be different.

=head1 DESCRIPTION

This provides utility methods that return information about the current
rate limit status.

=cut

requires qw/ua rate_limit_status/;

# Rate limiting changed so dramatically with v1.1 this Role simply won't work with it
excludes 'Net::Twitter::Role::API::RESTv1_1';

has _rate_limit_status => (
    isa      => 'HashRef[Int]',
    is       => 'rw',
    init_arg => undef,
    lazy     => 1,
    default  => sub { my %h; @h{qw/rate_limit rate_reset rate_remaining/} = (0,0,0); \%h },
);

around rate_limit_status => sub {
    my $orig = shift;
    my $self = shift;

    my $r = $self->$orig(@_) || return;

    @{$self->_rate_limit_status}{qw/rate_remaining rate_reset rate_limit/} =
        @{$r}{qw/remaining_hits reset_time_in_seconds hourly_limit/};

    return $r;
};

for my $method ( qw/rate_remaining rate_limit/ ) {
   around $method => sub {
        my $orig = shift;
        my $self = shift;

        $self->rate_reset; # force a call to rate_limit_satus if necessary;

        return $self->$orig(@_);
    };
}

after BUILD => sub {
    my $self = shift;

    weaken $self;

    $self->ua->add_handler(response_done => sub {
        my $res = shift;

        my @values = map { $res->header($_) }
                     qw/x-ratelimit-remaining x-ratelimit-reset x-ratelimit-limit/;

        return unless @values == 3;

        @{$self->_rate_limit_status}{qw/rate_remaining rate_reset rate_limit/} = @values;
    });
};

=head1 METHODS

If current rate limit data is not resident, these methods will force a call to
C<rate_limit_status>.  Therefore, any of these methods can throw an error.

=over 4

=item rate_remaining

Returns the number of API calls available before the next reset.

=cut

sub rate_remaining { shift->_rate_limit_status->{rate_remaining} }

=item rate_reset

Returns the Unix epoch time of the next reset.

=cut

sub rate_reset {
    my $self = shift;

    # If rate_reset is in the past, we need to refresh it
    $self->rate_limit_status if $self->_rate_limit_status->{rate_reset} < time;

    # HACK! Prevent a loop on clock mismatch
    my $time = time;
    if ( $self->_rate_limit_status->{rate_reset} < $time ) {
        $self->_rate_limit_status->{rate_reset} = $time + 1;
    }

    return $self->_rate_limit_status->{rate_reset};
}

=item rate_limit

Returns the current hourly rate limit.

=cut

sub rate_limit { shift->_rate_limit_status->{rate_limit} }

=item rate_ratio

Returns remaining API call limit, divided by the time remaining before the next
reset, as a ratio of the total rate limit per hour.

For example, if C<rate_limit> is 150, the total rate is 150 API calls per hour.
If C<rate_remaining> is 75, and there 1800 seconds (1/2 hour) remaining before
the next reset, C<rate_ratio> returns 1.0, because there are exactly enough
API calls remaining to maintain he full rate of 150 calls per hour.

If C<rate_remaining> is 30 and there are 360 seconds remaining before reset,
C<rate_ratio> returns 2.0, because there are enough API calls remaining
to maintain twice the full rate of 150 calls per hour.

As a final example, if C<rate_remaining> is 15, and there are 7200 seconds
remaining before reset, C<rate_ratio> returns 0.5, because there are only
enough API calls remaining to maintain half the full rate of 150 calls per
hour.

=cut

sub rate_ratio {
    my $self = shift;

    my $full_rate = $self->rate_limit / 3600;
    my $current_rate = try { $self->rate_remaining / ($self->rate_reset - time) } || 0;
    return $current_rate / $full_rate;
}

=item until_rate($target_ratio)

Returns the number of seconds to wait before making another rate limited API
call such that C<$target_ratio> of the full rate would be available.  It
always returns a number greater than, or equal to zero.

Use a target rate of 1.0 in a timeline polling loop to get a steady polling
rate, using all the allocated calls, and adjusted for other API calls as they
occur.

Use a target rate E<lt> 1.0 to allow a process to make calls as fast as
possible but not consume all of the calls available, too soon.  For example, if
you have a process building a large social graph, you may want to allow it make
as many calls as possible, with no wait, until 20% of the available rate
remains.  Use a value of 0.2 for that purpose.

A target rate E<gt> than 1.0 can be used for a process that should only use
"extra" available API calls.  This is useful for an application that requires
most of it's rate limit for normal operation.

=cut

sub until_rate {
    my ( $self, $target_rate ) = @_;

    my $s = $self->rate_reset - time - 3600 * $self->rate_remaining / $target_rate / $self->rate_limit;
    return $s > 0 ? $s : 0;
};

1;

__END__

=back

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

Copyright (c) 2009 Marc Mims

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
