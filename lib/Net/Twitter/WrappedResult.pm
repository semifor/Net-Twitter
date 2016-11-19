package Net::Twitter::WrappedResult;

use Moose;

# decoded JSON Twitter API response
has result => (
    is       => 'ro',
    required => 1,
);

has http_response => (
    is       => 'ro',
    isa      => 'HTTP::Response',
    required => 1,
);

# private method
my $limit = sub {
    my ( $self, $which ) = @_;

    my $res = $self->http_response;

    # I'd like to use //, but...old perls. Sigh.
    my $value = $res->header("X-Rate-Limit-$which");
    return defined $value ? $value
        # TODO: is FeatureRateLimit still a thing?
        : $res->header("X-FeatureRateLimit-$which");
};

sub rate_limit           { shift->$limit('Limit')     }
sub rate_limit_remaining { shift->$limit('Remaining') }
sub rate_limit_reset     { shift->$limit('Reset')     }

no Moose;

1;

__END__

=head1 NAME

Net::Twitter::WrappedResult - Wrap an HTTP response and Twitter result

=head1 SYNOPSIS

    use Net::Twitter;

    my $nt = Net::Twitter->new(
        traits => [ qw/API::RESTv1_1 WrapResult/ ],
        %other_new_options,
    );

    my $r = $nt->verify_credentials;

    my $http_response        = $r->http_response;
    my $twitter_result       = $r->result;
    my $rate_limit_remaining = $r->rate_limit_remaining;

=head1 DESCRIPTION

Often, the result of a Twitter API call, inflated from the JSON body of the
HTTP response does not contain all the information you need. Twitter includes
meta data, such as rate limiting information, in HTTP response headers. This
object wraps both the inflated Twitter result and the HTTP response giving the
caller full access to all the meta data. It also provides accessors for the
rate limit information.

=head1 METHODS

=over 4

=item new(result => $twitter_result, http_response => $http_response)

Constructs an object wrapping the Twitter result and HTTP response.

=item result

Returns the Twitter API result, i.e., the decode JSON response body.

=item http_response

Returns the L<HTTP::Response> object for the API call.

=item rate_limit

Returns the rate limit, per 15 minute window, for the API endpoint called.
Returns undef if no suitable rate limit header is available.

=item rate_limit_remaining

Returns the calls remaining in the current 15 minute window for the API
endpoint called. Returns undef if no suitable header is available.

=item rate_limit_reset

Returns the Unix epoch time time of the next 15 minute window, i.e., when the
rate limit will be reset, for the API endpoint called.  Returns undef if no
suitable header is available.

=back

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2016 Marc Mims

This program is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

