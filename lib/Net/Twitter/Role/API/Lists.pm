package Net::Twitter::Role::API::Lists;

use Moose::Role;
use Net::Twitter::API;
use DateTime::Format::Strptime;
use Try::Tiny;

with 'Net::Twitter::Role::API::REST';

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
  $users = $nt->add_list_members($owner, $list_id, { screen_name => \@screen_names });

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

=head1 DEPRECATION NOTICE

This module implements methods for the original Twitter Lists API.  Twitter has
deprecated these API methods and reimplemented them with a saner semantics.
The new methods are implemented in the API::REST trait,
L<Net::Twitter::Role::API::REST>.  This module provides backwards
compatibility for code written to use the original Lists API.  To use the
new API methods, simply remove this trait from your code and change the
arguments to its methods to match the new semantics.

This module may be dropped from L<Net::Twitter> in a future release.  It will
remain as long as Twitter still provides the underlying API end-points.

=head1 DESCRIPTION

This module adds support to L<Net::Twitter> for the Twitter Lists API.

=cut

requires qw/username ua/;


=head1 DESCRIPTION

B<Net::Twitter::Role::API::Lists> provides a trait for the Twitter Lists API methods.
See L<Net::Twitter> for full documentation.

=cut

has lists_api_url => ( isa => 'Str', is => 'rw', default => 'http://api.twitter.com/1' );

base_url     'lists_api_url';
authenticate 1;

our $DATETIME_PARSER = DateTime::Format::Strptime->new(pattern => '%a %b %d %T %z %Y');
datetime_parser $DATETIME_PARSER;

after BUILD => sub {
    my $self = shift;

    $self->{lists_api_url} =~ s/^http:/https:/ if $self->ssl;
};

twitter_api_method legacy_create_list => (
    path        => ':user/lists',
    method      => 'POST',
    params      => [qw/user name mode description/],
    required    => [qw/user name/],
    returns     => 'HashRef',
    description => <<'',
Creates a new list for the authenticated user. The C<mode> parameter may be
either C<public> or C<private>.  If not specified, it defaults to C<public>.

);

twitter_api_method legacy_update_list => (
    path        => ':user/lists/:list_id',
    method      => 'POST',
    params      => [qw/user list_id name mode description/],
    required    => [qw/user list_id/],
    returns     => 'HashRef',
    description => <<'',
Updates a list to change the name, mode, description, or any combination thereof.

);

twitter_api_method legacy_get_lists => (
    path        => ':user/lists',
    method      => 'GET',
    params      => [qw/user cursor/],
    required    => [qw/user/],
    returns     => 'ArrayRef[List]',
    aliases     => [qw/legacy_list_lists/],
    description => <<'EOT',
Returns a reference to an array of lists owned by the specified user.  If the
user is the authenticated user, it returns both public and private lists.
Otherwise, it only returns public lists.

When the C<cursor> parameter is used, a hash reference is returned; the lists
are returned in the C<lists> element of the hash.
EOT
);

twitter_api_method legacy_get_list => (
    path        => ':user/lists/:list_id',
    method      => 'GET',
    params      => [qw/user list_id/],
    required    => [qw/user list_id/],
    returns     => 'HashRef',
    description => <<'',
Returns the specified list as a hash reference.

);

twitter_api_method legacy_delete_list => (
    path        => ':user/lists/:list_id',
    method      => 'DELETE',
    params      => [qw/user list_id/],
    required    => [qw/user list_id/],
    description => <<'',
Deletes a list owned by the authenticating user. Returns the list as a hash
reference.

);

twitter_api_method legacy_list_statuses => (
    path        => ':user/lists/:list_id/statuses',
    method      => 'GET',
    params      => [qw/user list_id since_id max_id per_page page/],
    required    => [qw/user list_id/],
    returns     => 'ArrayRef[Status]',
    description => <<'',
Returns a timeline of list member statuses as an array reference.

);

twitter_api_method legacy_list_memberships => (
    path        => ':user/lists/memberships',
    method      => 'GET',
    params      => [qw/user cursor/],
    required    => [qw/user/],
    description => <<'EOT',
Returns the lists the specified user is a member of as an array reference.

When the C<cursor> parameter is used, a hash reference is returned; the lists
are returned in the C<lists> element of the hash.
EOT
);

twitter_api_method legacy_list_subscriptions => (
    path        => ':user/lists/subscriptions',
    method      => 'GET',
    params      => [qw/user cursor/],
    required    => [qw/user/],
    description => <<'EOT',
Returns a lists to which the specified user is subscribed as an array reference.

When the C<cursor> parameter is used, a hash reference is returned; the lists
are returned in the C<lists> element of the hash.
EOT
);

twitter_api_method legacy_list_members => (
    path        => ':user/:list_id/members',
    method      => 'GET',
    params      => [qw/user list_id id cursor/],
    required    => [qw/user list_id/],
    returns     => 'ArrayRef[User]',
    description => <<'EOT',
Returns the list members as an array reference.

The optional C<id> parameter can be used to determine if the user specified by
C<id> is a member of the list.  If so, the user is returned as a hash
reference; if not, C<undef> is returned.

When the C<cursor> parameter is used, a hash reference is returned; the members
are returned in the C<users> element of the hash.
EOT
);

around legacy_list_members => sub {
    my $orig = shift;
    my $self = shift;

    $self->_user_or_undef($orig, 'member', @_);
};

twitter_api_method legacy_is_list_member => (
    path        => ':user/:list_id/members/:id',
    method      => 'GET',
    params      => [qw/user list_id id/],
    required    => [qw/user list_id id/],
    returns     => 'ArrayRef[User]',
    description => <<'EOT',
Returns the list member as a HASH reference if C<id> is a member of the list.
Otherwise, returns undef.
EOT
);

around legacy_is_list_member => sub {
    my $orig = shift;
    my $self = shift;

    $self->_user_or_undef($orig, 'member', @_);
};

twitter_api_method legacy_add_list_member => (
    path        => ':user/:list_id/members',
    method      => 'POST',
    returns     => 'User',
    params      => [qw/user list_id id/],
    required    => [qw/user list_id id/],
    description => <<'EOT',
Adds the user identified by C<id> to the list.

Returns a reference the added user as a hash reference.
EOT
);

twitter_api_method legacy_members_create_all => (
    aliases     => [qw/legacy_add_list_members/],
    path        => ':user/:list_id/members/create_all',
    method      => 'POST',
    returns     => 'ArrayRef[User]',
    params      => [qw/user list_id screen_name user_id/],
    required    => [qw/user list_id/],
    description => <<'EOT',
Adds multiple users C<id> to the list. Users are specified with the C<screen_name>
or C<user_id> parameter with a reference to an ARRAY of values.

Returns a reference the added user as a hash reference.
EOT
);

twitter_api_method legacy_delete_list_member => (
    path        => ':user/:list_id/members',
    method      => 'DELETE',
    params      => [qw/user list_id id/],
    required    => [qw/user list_id id/],
    aliases     => [qw/legacy_remove_list_member/],
    description => <<'EOT',
Deletes the user identified by C<id> from the specified list.

Returns the deleted user as a hash reference.
EOT
);

twitter_api_method legacy_list_subscribers => (
    path        => ':user/:list_id/subscribers',
    method      => 'GET',
    params      => [qw/user list_id id cursor/],
    required    => [qw/user list_id/],
    returns     => 'ArrayRef[User]',
    description => <<'EOT',
Returns the subscribers to a list as an array reference.

When the C<cursor> parameter is used, a hash reference is returned; the subscribers
are returned in the C<users> element of the hash.
EOT
);

around legacy_list_subscribers => sub {
    my $orig = shift;
    my $self = shift;

    $self->_user_or_undef($orig, 'subscriber', @_);
};

twitter_api_method legacy_is_list_subscriber => (
    path        => ':user/:list_id/subscribers/:id',
    method      => 'GET',
    params      => [qw/user list_id id/],
    required    => [qw/user list_id id/],
    returns     => 'ArrayRef[User]',
    aliases     => [qw/legacy_is_subscribed_list/],
    description => <<'EOT',
Returns the subscriber as a HASH reference if C<id> is a subscriber to the list.
Otherwise, returns undef.
EOT
);

around legacy_is_list_subscriber => sub {
    my $orig = shift;
    my $self = shift;

    $self->_user_or_undef($orig, 'subscriber', @_);
};

twitter_api_method legacy_subscribe_list => (
    path        => ':user/:list_id/subscribers',
    method      => 'POST',
    returns     => 'List',
    params      => [qw/user list_id/],
    required    => [qw/user list_id/],
    description => <<'',
Subscribes the authenticated user to the specified list.

);

twitter_api_method legacy_unsubscribe_list => (
    path        => ':user/:list_id/subscribers',
    method      => 'DELETE',
    returns     => 'List',
    params      => [qw/user list_id/],
    required    => [qw/user list_id/],
    description => <<'',
Unsubscribes the authenticated user from the specified list.

);

for my $method ( qw/
        create_list
        update_list
        get_lists
        get_list
        delete_list
        list_statuses
        list_memberships
        list_subscriptions
        list_members
        is_list_member
        add_list_member
        members_create_all
        delete_list_member
        list_subscribers
        is_list_subscriber
        subscribe_list
        unsubscribe_list
        list_lists
        add_list_members
        remove_list_member
        is_subscribed_list
    / )
{
    my $legacy_method = "legacy_$method";
    around $method => sub {
        my $orig = shift;
        my $self = shift;

        my $args = ref $_[-1] eq 'HASH' ? pop : {};
        my $legacy = exists $args->{-legacy_lists_api} ? delete $args->{-legacy_lists_api} : 1;
        return $self->$legacy_method(@_, $args) if $legacy;

        $self->$orig(@_, $args);
    };
}

1;

__END__

=head1 SEE ALSO

L<Net::Twitter>

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 COPYRIGHT

Copyright (c) 2009-2010 Marc Mims

=head1 LICENSE

This library is free software. You may redistribute and modify it under the
same terms as Perl itself.

=cut
