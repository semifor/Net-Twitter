package Net::Twitter::OAuth::AccessTokenRequest;
use warnings;
use strict;
use base 'Net::OAuth::Request';

# Just a copy of Net::OAuth::AccessTokenRequest with optional message param "verifier" added

__PACKAGE__->add_required_message_params(qw/token/);
__PACKAGE__->add_optional_message_params(qw/verifier/);
__PACKAGE__->add_required_api_params(qw/token_secret/);
sub allow_extra_params {0}
sub sign_message {1}

=head1 NAME

Net::Twitter::OAuth::AccessTokenRequest - A Twitter specific OAuth protocol request for an Access Token

=head1 DESCRIPTION

This is a copy of C<Net::OAuth::AccessTokenRequest> that adds the optional
message parameter C<verifier> used by Twitter.  (The C<verifier> parameter is
set to the PIN number that is presented to users while authenticating desktop
applications.

=head1 SEE ALSO

L<Net::OAuth>, L<http://oauth.net>

=head1 AUTHOR

Keith Grennan, C<< <kgrennan at cpan.org> >>

Marc Mims <marc@questright.com>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Keith Grennan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
