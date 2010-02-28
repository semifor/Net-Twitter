package Net::Twitter::OAuth::XAuthRequest;
use warnings;
use strict;
use base 'Net::OAuth::Request';

__PACKAGE__->add_extension_param_pattern(qr/x_auth_/);
__PACKAGE__->add_required_message_params(qw/
    x_auth_username
    x_auth_password
    x_auth_mode
/);
sub allow_extra_params {0}
sub sign_message {1}

=head1 NAME

Net::Twitter::OAuth::XAuthRequest - An OAuth protocol request for Twitter xAuth

=head1 SEE ALSO

L<Net::OAuth>, L<http://oauth.net>

=head1 AUTHOR

Marc Mims C<marc@questright.com>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Marc Mims, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
