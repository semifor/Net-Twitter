package Net::Twitter::Role::API::Lists;
use Moose::Role;
use Carp;
use DateTime::Format::Strptime;
use URI::Escape();

=head1 NAME

Net::Twitter::Role::API::Lists - Twitter Lists API support for Net::Twitter

=head1 SYNOPSIS

  use Net::Twitter;

  my $nt = Net::Twitter->new(traits => ['API::Lists']);
  $nt->credentials($username, $password);

  my $list = $nt->create_list(
      $my_screen_name,
      { name => 'My List Name', mode => private }
  );

  my $r = $nt->add_list_member(
      $my_screen_name,
      $list->{slug},
      { id => $member_user_id }
  );


=head1 DESCRIPTION

This module add support to L<Net::Twitter> for the Twitter Lists API.

The module is experimental and the method names, parameters, and implementation
may change without notice.  The Twitter Lists API itself is in beta ad the
documentation is just a draft.  When the Twitter Lists API specification is
stable, expect a stable release of this module.

=cut

requires qw/username ua/;


=head1 METHODS

Currently, the API::Lists methods can be called with positional parameters for
the parameters used to compose the URI path.  Additional parameters, including
both required and optional parameters are passed in a HASH reference as the
final argument to the API.  All parameters may be passed in the HASH ref, if
preferred.

Many of the methods take a C<slug> parameter.  The C<slug> is a URI safe
identifier assigned by Twitter for each list, based on the list's name.  A
C<slug> is unique to a user, but is not globally unique.  To identify a
specific list, both the C<user> and C<slug> parameters are required.

=over 4

=item new

The following arguments are available to new (in addition to those documented
in L<Net::Twitter>).

=over 4

=item lists_api_url

The base URL for the Twitter Lists API. Defaults to C<http://twitter.com>

=cut

has lists_api_url => ( isa => 'Str', is => 'rw', default => 'http://twitter.com' );

=back

=cut

has _lists_dt_parser => ( isa => 'Object', is => 'rw', default => sub {
        DateTime::Format::Strptime->new(pattern => '%a %b %d %T %z %Y')
    }
);

sub _lists_api_call {
    my ( $self, $http_method, $uri_parts, $api_mask, @args ) = @_;

    {
        # sanity check: ensure placeholder count matches uri parts count
        my $placeholders = $api_mask =~ tr/%/%/;
        my $uri_parts_count = @$uri_parts;
        croak "placeholder count ($placeholders) must equal uri_parts_count ($uri_parts_count)"
            unless $placeholders == $uri_parts_count;
    }

    my $args = @args && ref $args[-1] eq 'HASH' ? pop @args : {};

    # normalize $uri_parts and $api_mask for user parameter which must always be present
    unshift @$uri_parts, 'user';
    unshift @args, delete $args->{user} if exists $args->{user};
    $api_mask = "%s/$api_mask";

    my @uri_parts;
    for my $positional_arg ( @args ) {
        croak "too many positional parameters" unless shift @$uri_parts;
        push @uri_parts, $positional_arg;
    }

    for my $k ( @$uri_parts ) {
        croak "$k required" unless exists $args->{$k};

        push @uri_parts, delete $args->{$k};
    }

    # make the parameters URI safe
    @uri_parts = map { URI::Escape::uri_escape($_) } @uri_parts;

    my $base = $self->lists_api_url;
    my $uri = URI->new(sprintf "$base/$api_mask.json", @uri_parts);

    my $res = $self->_authenticated_request($http_method, $uri, $args, 1);

    return $self->_parse_result($res, {}, $self->_lists_dt_parser);
}

=item create_list

Parameters: user, name, mode
Required: user, name

Creates a new list for the authenticated user. The C<mode> parameter may be
either C<public> or C<private>.  If not specified, it defaults to C<public>.

=cut

sub create_list {
    my ($self, @args) = @_;

    return $self->_lists_api_call('POST', [], 'lists', @args);
}

=item update_list

Parameters: user, slug, name, mode

Updates a list to change the name, mode, or both.

=cut

sub update_list {
    my ($self, @args) = @_;

    return $self->_lists_api_call('POST', ['slug'], "lists/%s", @args);
}

=item list_lists

Parameters: user

Returns the lists for the specified user.  If the user is the authenticated
user, it returns both public and private lists.  Otherwise, it only returns the
public lists.

=cut

sub list_lists {
    my ($self, @args) = @_;

    return $self->_lists_api_call('GET', [], 'lists', @args);
}

=item list_memberships

Parameters: $user

Returns a the lists for which the specified user is a member.

=cut

sub list_memberships {
    my ($self, @args) = @_;

    return $self->_lists_api_call('GET', [], 'lists/memberships', @args);
}

=item delete_list

Parameters: user, slug

Deletes a list.

=cut

sub delete_list {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('DELETE', ['slug'], "lists/%s", @args);
}


=item list_statuses

Parameters: user, slug, [ next_cursor | previous_cursor ]

Returns the statuses for list members.  The optional cursor parameters provide
paging.

=cut

sub list_statuses {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('GET', ['slug'], "lists/%s/statuses", @args);
}

=item get_list

Parameters: user, slug

Returns the specified list.

=cut

sub get_list {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('GET', ['slug'], "lists/%s", @args);
}

=item add_list_member

Parameters: user, slug, id

Adds the user identified by C<id> to the specified list.

=cut

sub add_list_member {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('POST', ['slug'], "%s/members", @args);
}

=item list_members

Parameters: user, slug, [ id ]

Returns the members of the specified list.  Use the optional C<id> parameter to
check the list to see if user C<id> is a member.

=cut

sub list_members {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('GET', ['slug'], "%s/members", @args);
}

=item remove_list_member

Parameters: user, slug, id

Removes the member with C<id> from the specified list.

=cut

sub remove_list_member {
    my ( $self, @args ) = @_;
    
    return $self->_lists_api_call('DELETE', ['slug'], "%s/members", @args);
}

=item subscribe_list

Parameters: user, slug

Subscribes the authenticated user to the specified list.

=cut

sub subscribe_list {
    my ( $self, @args ) = @_;
    
    return $self->_lists_api_call('POST', ['slug'], "%s/subscribers", @args);
}

=item list_subscribers

Parameters: user, slug

Returns the subscribers to the specified list.

=cut

sub list_subscribers {
    my ( $self, @args ) = @_;
    
    return $self->_lists_api_call('GET', ['slug'], "%s/subscribers", @args);
}

=item unsubscribe_list

Parameters: user, slug

Unsubscribes the authenticated user from the specified list.

=cut

sub unsubscribe_list {
    my ( $self, @args ) = @_;
    
    return $self->_lists_api_call('DELETE', ['slug'], "%s/subscribers", @args);
}

=item is_subscribed_list

Parameters: user, slug, id

Check to see if the user identified by C<id> is subscribed to the specified
list.

=cut

sub is_subscribed_list {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('GET', [qw/slug id/], "%s/subscribers/%s", @args);
}

=back

=cut
    
1;

__END__

=head1 SEE ALSO

L<Net::Twitter>

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT

Copyright (c) 2009 Marc Mims

=head1 LICENSE

This library is free software. You may redistribute and modify it under the
same terms as Perl itself.

=cut
