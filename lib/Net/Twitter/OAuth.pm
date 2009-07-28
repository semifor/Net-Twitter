package Net::Twitter::OAuth;
use Moose;

# use *all* digits for fBSD ports
our $VERSION = '3.04004';
$VERSION = eval $VERSION; # numify for warning-free dev releases

extends  'Net::Twitter::Core';
with map "Net::Twitter::Role::$_", qw/Legacy OAuth/;

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Twitter::OAuth - Net::Twitter with 'Legacy' and 'OAuth' roles for backwards compatibility

=head1 SYNOPSIS

  use Net::Twitter;

  my $nt = Net::Twitter::OAuth->new(consumer_key => $key, consumer_secret => $secret);

=head1 DESCRIPTION

This module simply creates an instance of C<Net::Twitter> with the C<Legacy>
and C<OAuth> traits applied.  It is provided as a transparent backwards
compatibility layer for earlier versions of Net::Twitter::OAuth which
subclassed Net::Twitter.

See L<Net::Twitter> and L<Net::Twitter::Role::OAuth> for full documentation.

=head1 DEPRECATION NOTICE

This module is deprecated.  Use L<Net::Twitter> instead.

    use Net::Twitter;

    # Just the REST API; exceptions thrown on error
    $nt = Net::Twitter->new(traits => [qw/API::REST OAuth/]);

    # Just the REST API; errors wrapped - use $nt->get_error
    $nt = Net::Twitter->new(traits => [qw/API::REST WrapError/]);

    # Or, for code that uses legacy Net::Twitter idioms
    $nt = Net::Twitter->new(traits => [qw/Legacy OAuth/]);

=head1 METHODS

=over 4

=item new

Creates a C<Net::Twitter> object with the C<Legacy> and C<OAuth> traits.  See
L<Net::Twitter/new> for C<new> options.

=back

=head1 SEE ALSO

L<Net::Twitter>, L<Net::Twitter::Role::OAuth>


=head1 AUTHORS

Marc Mims <marc@questright.com>
Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
