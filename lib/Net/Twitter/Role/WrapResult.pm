package Net::Twitter::Role::WrapResult;

use Moose::Role;
use Net::Twitter::WrappedResult;

requires '_parse_result';

around _parse_result => sub {
    my ( $next, $self ) = splice @_, 0, 2;

    my $http_response = $_[0];
    my $result = $self->$next(@_);

    return Net::Twitter::WrappedResult->new(
        result        => $result,
        http_response => $http_response,
    );
};

no Moose::Role;

1;

__END__

=head1 NAME

Net::Twitter::Role::WrapResult - Wrap Twitter API response and HTTP Response

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

Normally, Net::Twitter API methods return the decoded JSON body from the HTTP response. Some useful information, notably rate limit information, is included in HTTP response headers. With this role applied, API methods will return a L<Net::Twitter::WrappedResult> object that includes both the HTTP response and the decoded JSON response body. See L<Net::Twitter::WrappedResult> for details.

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT

Copyright (c) 2016 Marc Mims

=head1 LICENSE

This library is free software and may be distributed under the same terms as perl itself.

=cut
