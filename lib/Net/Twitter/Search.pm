package Net::Twitter::Search;
use Moose;

# use *all* digits for fBSD ports
our $VERSION = '3.03003';
$VERSION = eval $VERSION; # numify for warning-free dev releases

extends 'Net::Twitter::Core';
with    "Net::Twitter::Role::Legacy";

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Twitter::Search - A perl interface to the Twitter Search API

=head1 SYNOPSIS

  use Net::Twitter;

  $nt = Net::Twitter::Search->new;

  $tweets = $nt->search('net_twitter');

=head1 DESCRIPTION

This module simply creates an instance of C<Net::Twitter> with the C<Legacy>
trait for backwards compatibility with prior versions.  Consider
L<Net::Twitter::Lite> if you need a lighter, non-Moose alternative.

See L<Net::Twitter> for full documentation.

=head1 DEPRECATION NOTICE

This module is deprecated.  Use L<Net::Twitter> instead.

    use Net::Twitter;

    # Just the Search API; exceptions thrown on error
    $nt = Net::Twitter->new(traits => [qw/API::Search/]);

    # Just the Search API; errors wrapped - use $nt->get_error
    $nt = Net::Twitter->new(traits => [qw/API::Search WrapError/]);

    # Or, for code that uses legacy Net::Twitter idioms
    $nt = Net::Twitter->new(traits => [qw/Legacy/]);

    $tweets = $nt->search('pot of gold');

=head1 METHODS

=over 4

=item new

Creates a C<Net::Twitter> object with the C<Legacy> trait.  See
L<Net::Twitter/new> for C<new> options.

=back

=head1 SEE ALSO

=over 4

=item L<Net::Twitter>

Full documentation.

=back

=head1 AUTHORS

Marc Mims <marc@questright.com>
Chris Thompson <cpan@cthompson.com>
Brenda Wallace <brenda@wallace.net.nz>

=head1 LICENSE

Copyright (c) 2009 Marc Mims

The Twitter API itself, and the description text used in this module is:

Copyright (c) 2009 Twitter

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
