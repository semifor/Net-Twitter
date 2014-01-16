package Net::Twitter::Role::RetryOnError;

use Moose::Role;
use namespace::autoclean;
use Time::HiRes;

requires '_send_request';

=head1 NAME

Net::Twitter::Role::RetryOnError - Retry Twitter API calls on error

=head1 SYNOPSIS

    use Net::Twitter;
    $nt = Net::Twitter->new(
        traits      => ['API::RESTv1_1', 'RetryOnError']
        max_retries => 3,
    );

=head1 DESCRIPTION

Temporary errors are not uncommon when calling the Twitter API.  When applied
to L<Net::Twitter> this role will provide automatic retries of API calls in a very
configurable way.

It only retries when the response status code is E<gt>= 500.  Other error codes
indicate a permanent error.  If the maximum number of retries is reached,
without success, an exception is thrown, as usual.


=head1 OPTIONS

This role adds the following options to C<new>:

=over 4

=item initial_retry_delay

A floating point number specifying the initial delay, after an error, before
retrying.  Default: 0.25 (250 milliseconds).

=cut

has initial_retry_delay => (
    is      => 'rw',
    isa     => 'Num',
    default => 0.250, # 250 milliseconds
);

=item max_retry_delay

A floating point number specifying the maximum delay between retries.  Default: 4.0

=cut

has max_retry_delay => (
    is      => 'rw',
    isa     => 'Num',
    default => 4.0,   # 4 seconds
);

=item retry_delay_multiplier

On the second and subsequent retries, a new delay is calculated by multiplying the previous
delay by C<retry_delay_multiplier>. Default: 2.0

=cut

has retry_delay_multiplier => (
    is      => 'rw',
    isa     => 'Num',
    default => 2,     # double the prior delay
);

=item max_retries

The maximum number of consecutive retries before giving up and throwing an exception.
If set to 0, it the API call will be retried indefinitely. Default 5.

=cut

has max_retries => (
    is        => 'rw',
    isa       => 'Int',
    default   => 5,   # 0 = try forever
);

=item retry_delay_code

A code reference that will be called to handle the delay.  It is passed a
single argument: a floating point number specifying the number of seconds to
delay.  By default, L<Time::HiRes/sleep> is called.

If you're using a non-blocking user agent, like L<Coro::LWP>, you should use
this option to provide a non-blocking delay.

=cut

has retry_delay_code => (
    is      => 'rw',
    isa     => 'CodeRef',
    default => sub {
        sub { Time::HiRes::sleep(shift) };
    },
);

=back

=cut

around _send_request => sub {
    my ( $orig, $self, $msg ) = @_;

    my $is_oauth = do {
        my $auth_header = $msg->header('authorization');
        $auth_header && $auth_header =~ /^OAuth /;
    };

    my $delay = $self->initial_retry_delay;
    my $retries = $self->max_retries;
    while () {
        my $res = $self->$orig($msg);

        return $res if $res->is_success || $retries-- == 0 || $res->code < 500;

        $self->retry_delay_code->($delay);
        $delay *= $self->retry_delay_multiplier;
        $delay  = $self->max_retry_delay if $delay > $self->max_retry_delay;

        # If this is an OAuth request, we need a new Authorization header
        # (the nonce may be invalid, now).
        $self->_add_authorization_header($msg) if $is_oauth;
    }
};


1;

__END__

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT

Copyright (c) 2010 Marc Mims

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.

=cut
