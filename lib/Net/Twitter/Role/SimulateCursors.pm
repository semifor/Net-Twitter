package Net::Twitter::Role::SimulateCursors;
use Moose::Role;
use namespace::autoclean;

requires qw/_json_request/;

around _json_request => sub {
    my $orig = shift;
    my $self = shift;
    my ($http_method, $uri, $args, $authenticate) = @_;

    if ( defined(my $cursor = delete $args->{cursor}) ) {
        my $page = $cursor == -1 ? 1 : $cursor;
        my $r = $self->$orig($http_method, $uri, { %$args, page => $page }, $authenticate);

        my $key = $uri =~ qr`/ids\.` ? 'ids' : 'users';

        my $next_cursor     = @$r ? $page + 1 : 0;
        my $previous_cursor = $page == 1 ? 0 : $page - 1;

        return {
            next_cursor         => $next_cursor,
            next_cursor_str     => "$next_cursor",
            previous_cursor     => $previous_cursor,
            previous_cursor_str => "$previous_cursor",
            $key                => $r,
        };
    }

    return $self->$orig(@_);
};

1;

__END__

=head1 NAME

Net::Twitter::Role::SimulateCursors - Make paging work like cursoring

=head1 SYNOPSIS

  use Net::Twitter;

  my $nt = Net::Twitter->new(
      traits          => ['API::REST', 'SimulateCursors'],
  );


=head1 DESCRIPTION

This role simulates the cursoring method used by some Twitter API methods.  It's useful
for providing compatibility with Identi.ca, for instance, that does not support cursoring
and requires paging, instead.


=head1 METHODS

=over 4


=back

=head1 AUTHOR

Marc Mims E<lt>marc@questright.comE<gt>


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Net::Twitter>

=cut

