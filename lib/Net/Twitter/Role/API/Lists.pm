package Net::Twitter::Role::API::Lists;
use Moose::Role;
use Carp;
use DateTime::Format::Strptime;
use URI::Escape();
use Try::Tiny;

=head1 NAME

Net::Twitter::Role::API::Lists - Twitter Lists API support for Net::Twitter

=head1 SYNOPSIS

  use Net::Twitter;

  my $nt = Net::Twitter->new(traits => ['API::Lists'], ...);

  $list = $nt->create_list($owner, { name => $name, description => $desc });
  $list = $nt->update_list($owner, $list_id, { description => $desc });

  $lists = $nt->get_lists($owner);
  $lists = $nt->list_lists($owner);

  $list = $nt->get_list($owner, $list_id);
  $list = $nt->delete_list($owner, $list_id);

  $statuses = $nt->list_statuses($owner, $list_id);

  $lists = $nt->list_memberships($owner);
  $lists = $nt->list_subscriptions($owner);

  $users = $nt->list_members($owner, $list_id);

  $user_or_undef = $nt->list_members($owner, $list_id, { id => $user_id });

  $user = $nt->add_list_member($owner, $list_id, $user_id);

  $user = $nt->delete_list_member($owner, $list_id, $user_id);
  $user = $nt->remove_list_member($owner, $list_id, $user_id);

  $user_or_undef = $nt->is_list_member($owner, $list_id, $user_id);

  $users = $nt->list_subscribers($owner, $list_id);

  $list = $nt->subscribe_list($owner, $list_id);
  $list = $nt->unsubscribe_list($owner, $list_id);

  $user_or_undef = $nt->is_subscribed_list($owner, $list_id, $user_id);
  $user_or_undef = $nt->is_list_subscriber($owner, $list_id, $user_id);

  #############################
  # With the cursor parameter #
  #############################

  $r = $nt->get_list($user, $list_id, { cursor => $cursor });
  $lists = $r->{lists};

  $r = $nt->list_memberships($user, { cursor => $cursor });
  $lists = $r->{lists};

  $r = $nt->list_subscriptions($user, { cursor => $cursor });
  $lists = $r->{lists};

  $r = $nt->list_members($owner, $list_id, { cursor => $cursor });
  $users = $r->{users};

  $r = $nt->list_subscribers($owner, $list_id, { cursor => $cursor });
  $users = $r->{users};

=head1 DESCRIPTION

This module adds support to L<Net::Twitter> for the Twitter Lists API.

=cut

requires qw/username ua/;


=head1 METHODS

The API::Lists methods can be called with positional parameters for the
parameters used to compose the URI path.  Additional parameters, including both
required and optional parameters are passed in a HASH reference as the final
argument to the method. All parameters may be passed in the HASH ref, if
preferred.

Most methods take a C<list_id> parameter.  You can pass either the numeric ID
of the list or the list's C<slug>.  Both are returned by by the C<create_list>
call: C<< $list->{id} >> and C<< $list->{slug} >> respectively.

The C<slug> changes if the list is renamed.  The numeric ID does not.

The C<slug> is a URI safe identifier assigned by Twitter for each list, based
on the list's name.  A C<slug> is unique to a list owner, but is not globally
unique.

Many methods take an optional C<cursor> parameter.  See L<Net::Twitter/Cursors
and Paging> for details on using the C<cursor> parameter.  Without the cursor
parameter, these methods return a reference to an array of results (users, or
lists).  With it, they return a reference to a hash that contains
C<next_cursor>, C<previous_cursor>, and either C<users>, or C<lists>, as
appropriate, which is a reference to the array of results.

=over 4

=item new

This role makes the following additional arguments available to new.

=over 4

=item lists_api_url

The base URL for the Twitter Lists API. Defaults to C<http://api.twitter.com/1>

=cut

has lists_api_url => ( isa => 'Str', is => 'rw', default => 'http://api.twitter.com/1' );

=back

=cut

has _lists_dt_parser => ( isa => 'Object', is => 'rw', default => sub {
        DateTime::Format::Strptime->new(pattern => '%a %b %d %T %z %Y')
    }
);

after BUILD => sub {
    my $self = shift;

    $self->{lists_api_url} =~ s/^http:/https:/ if $self->ssl;
};

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

    # recast slug as list_id
    $args->{list_id} = delete $args->{slug} if exists $args->{slug};

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

sub _make_id_positional {
    my ( $self, $template, $positional_args, $args ) = @_;

    my $hash_args = ref $args->[-1] && pop @$args || {};
    if ( @$args > @$positional_args + 1 || exists $hash_args->{id} ) {
        push @$positional_args, 'id';
        $template .= '/%s';
    }

    push @$args, $hash_args if %$hash_args;

    return ($template, $positional_args);
}

=item create_list

Parameters: user [ name, mode, description ]
Required: user, name

Creates a new list for the authenticated user. The C<mode> parameter may be
either C<public> or C<private>.  If not specified, it defaults to C<public>.

Returns the list as a hash reference.

=cut

sub create_list {
    my ($self, @args) = @_;

    return $self->_lists_api_call('POST', [], 'lists', @args);
}

=item update_list

Parameters: user, list_id, [ name, mode, description ]

Updates a list to change the name, mode, description, or any combination thereof.

Returns the list as a hash reference.

=cut

sub update_list {
    my ($self, @args) = @_;

    return $self->_lists_api_call('POST', ['list_id'], "lists/%s", @args);
}

=item get_lists

Parameters: user, [ cursor ]

Returns a reference to an array of lists owned by the specified user.  If the
user is the authenticated user, it returns both public and private lists.
Otherwise, it only returns public lists.

When the C<cursor> parameter is used, a hash reference is returned; the lists
are returned in the C<lists> element of the hash.

=cut

sub get_lists {
    my ($self, @args) = @_;

    return $self->_lists_api_call('GET', [], 'lists', @args);
}

=item list_lists

An alias for get_lists

=cut

sub list_lists { shift->get_lists(@_) }

=item get_list

Parameters: user, list_id

Returns the specified list as a hash reference.

=cut

sub get_list {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('GET', ['list_id'], "lists/%s", @args);
}

=item delete_list

Parameters: user, list_id

Deletes a list owned by the authenticating user. Returns the list as a hash
reference.

=cut

sub delete_list {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('DELETE', ['list_id'], "lists/%s", @args);
}

=item list_statuses

Parameters: user, list_id, [ since_id, max_id, per_page, page ]

Returns a timeline of list member statuses as an array reference.

=cut

sub list_statuses {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('GET', ['list_id'], "lists/%s/statuses", @args);
}

=item list_memberships

Parameters: user, [ cursor ]

Returns the lists the specified user is a member of as an array reference.

When the C<cursor> parameter is used, a hash reference is returned; the lists
are returned in the C<lists> element of the hash.

=cut

sub list_memberships {
    my ($self, @args) = @_;

    return $self->_lists_api_call('GET', [], 'lists/memberships', @args);
}

=item list_subscriptions

Parameters: user, [ cursor ]

Returns a lists to which the specified user is subscribed as an array reference.

When the C<cursor> parameter is used, a hash reference is returned; the lists
are returned in the C<lists> element of the hash.

=cut

sub list_subscriptions {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('GET', [], "lists/subscriptions", @args);
}

=item list_members

Parameters: user, list_id, [ id, cursor ]

Returns the list members as an array reference.

The optional C<id> parameter can be used to determine if the user specified by
C<id> is a member of the list.  If so, the user is returned as a hash
reference; if not, C<undef> is returned.

When the C<cursor> parameter is used, a hash reference is returned; the members
are returned in the C<users> element of the hash.

=cut

sub list_members {
    my ( $self, @args ) = @_;

    my ( $template, $positional_args ) = $self->_make_id_positional('%s/members', [qw/list_id/], \@args);

    return try {
        $self->_lists_api_call('GET', $positional_args, $template, @args)
    }
    catch {
        die $_ unless /The specified user is not a member of this list/;
        return undef;
    };
}

=item add_list_member

Parameters: user, list_id, id

Adds the user identified by C<id> to the list.

Returns a reference the added user as a hash reference.

=cut

sub add_list_member {
    my ( $self, @args ) = @_;

    my $args = ref $args[-1] && pop @args || {};
    $args->{id} = pop @args if @args == 3 && !exists $args->{id};
    return $self->_lists_api_call('POST', ['list_id'], "%s/members", @args, $args);
}

=item delete_list_member

Parameters: user, list_id, id

Deletes the user identified by C<id> from the specified list.

Returns the deleted user as a hash reference.

=cut

sub delete_list_member {
    my ( $self, @args ) = @_;

    my $args = ref $args[-1] && pop @args || {};
    $args->{id} = pop @args if @args == 3 && !exists $args->{id};
    return $self->_lists_api_call('DELETE', ['list_id'], "%s/members", @args, $args);
}

=item remove_list_member

Parameters: user, list_id, id

An alias for C<delete_list_member>.

=cut

sub remove_list_member { shift->delete_list_member(@_) }

=item is_list_member

Parameters: user, list_id, id

Check to see if the user identified by C<id> is a member of the specified list.
Returns the user as a hash reference if so, C<undef> if not making it suitable
for boolean tests.

=cut

sub is_list_member {
    my ( $self, @args ) = @_;

    my $args = ref $args[-1] && pop @args || {};
    croak "id parameter is required" unless @args > 2 || exists $args->{id};
    return $self->list_members(@args, $args);
}

=item list_subscribers

Parameters: user, list_id, [ cursor ]

Returns the subscribers to a list as an array reference.

When the C<cursor> parameter is used, a hash reference is returned; the subscribers
are returned in the C<users> element of the hash.

=cut

sub list_subscribers {
    my ( $self, @args ) = @_;

    my ( $template, $positional_args ) = $self->_make_id_positional('%s/subscribers', [qw/list_id/], \@args);

    return try {
        $self->_lists_api_call('GET', $positional_args, $template, @args)
    }
    catch {
        die $_ unless /The specified user is not a subscriber of this list/;
        return undef;
    };
}

=item subscribe_list

Parameters: user, list_id

Subscribes the authenticated user to the specified list.

Returns the list as a hash reference.

=cut

sub subscribe_list {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('POST', ['list_id'], "%s/subscribers", @args);
}

=item unsubscribe_list

Parameters: user, list_id

Unsubscribes the authenticated user from the specified list.

Returns the list as a hash reference.

=cut

sub unsubscribe_list {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('DELETE', ['list_id'], "%s/subscribers", @args);
}

=item is_subscribed_list

Parameters: user, list_id, id

Check to see if the user identified by C<id> is subscribed to the specified
list.  If subscribed, returns the user as a hash reference, otherwise, returns
C<undef>, making it suitable for a boolean test.

=cut

sub is_subscribed_list {
    my ( $self, @args ) = @_;

    my $args = ref $args[-1] && pop @args || {};
    croak "id parameter is required" unless @args > 2 || exists $args->{id};
    return $self->list_subscribers(@args, $args);
}

=item is_list_subscriber

Parameters: user, list_id, id

An alias for C<is_subscribed_list>.

=cut

sub is_list_subscriber { shift->is_subscribed_list(@_) }

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
