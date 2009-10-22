package Net::Twitter::Role::API::Lists;
use Moose::Role;
use Carp;
use DateTime::Format::Strptime;
use URI::Escape();

requires qw/username ua/;

has lists_api_url => ( isa => 'Str', is => 'rw', default => 'http://twitter.com' );
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

# args: user => $user, name => $name, [ mode => 'public|private' ]
sub create_list {
    my ($self, $args) = @_;

    return $self->_lists_api_call('POST', [], 'lists', $args);
}

# args: user => $user, name => $name, [ mode => 'public|private' ]
sub update_list {
    my ($self, @args) = @_;

    return $self->_lists_api_call('POST', ['slug'], "lists/%s", @args);
}

# args: user => $user
sub list_lists {
    my ($self, @args) = @_;

    return $self->_lists_api_call('GET', [], 'lists', @args);
}

# args: user => $user
sub list_memberships {
    my ($self, @args) = @_;

    return $self->_lists_api_call('GET', [], 'lists/memberships', @args);
}

# args: user => $user, slug => $slug
sub delete_list {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('DELETE', ['slug'], "lists/%s", @args);
}

# args: user => $user, sulg => $slug, [ next_cursor | previous_cursor ]
sub list_statuses {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('GET', ['slug'], "lists/%s/statuses", @args);
}

# args: user, slug
sub get_list {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('GET', ['slug'], "lists/%s", @args);
}

# args: user, slug, id
sub add_list_member {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('POST', ['slug'], "%s/members", @args);
}

# args: user, slug, [ id ]
# if no member id is passed, get all subscribers; otherwise, check to
# see if the specified user (id) is subscribed
sub list_members {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('GET', ['slug'], "%s/members", @args);
}

# args: user, slug, id
sub remove_list_member {
    my ( $self, @args ) = @_;
    
    return $self->_lists_api_call('DELETE', ['slug'], "%s/members", @args);
}

# args: user slug
# subscribe the authenticated user to a list 
sub subscribe_list {
    my ( $self, @args ) = @_;
    
    return $self->_lists_api_call('POST', ['slug'], "lists/%s/subscribers", @args);
}

# args: user, slug
sub list_subscribers {
    my ( $self, @args ) = @_;
    
    return $self->_lists_api_call('GET', ['slug'], "lists/%s/subscribers", @args);
}

# args: user, slug
# unsubscribe the authenticated user from a list
sub unsubscribe_list {
    my ( $self, @args ) = @_;
    
    return $self->_lists_api_call('DELETE', ['slug'], "lists/%s/subscribers", @args);
}

# args: user, slug, id
sub subscribed_list {
    my ( $self, @args ) = @_;

    return $self->_lists_api_call('GET', [qw/slug id/], "%s/subscribers/%s", @args);
}
    
1;
