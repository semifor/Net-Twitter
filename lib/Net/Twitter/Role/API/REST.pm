package Net::Twitter::Role::API::REST;
use Moose::Role;

requires qw/credentials/;

use Net::Twitter::API;

requires qw/ua username password credentials/;

my $build_api_host = sub {
    my $uri = URI->new(shift->apiurl);
    join ':', $uri->host, $uri->port;
};

has apiurl          => ( isa => 'Str', is => 'ro', default => 'http://twitter.com'        );
has apihost         => ( isa => 'Str', is => 'ro', lazy => 1, default => $build_api_host  );
has apirealm        => ( isa => 'Str', is => 'ro', default => 'Twitter API'               );

around BUILDARGS => sub {
    my $next    = shift;
    my $class   = shift;
    my %options = @_;

    if ( delete $options{identica} ) {
        %options = (
            apiurl => 'http://identi.ca/api',
            apirealm => 'Laconica API',
            %options,
        );
    }

    return $next->($class, %options);
};

after credentials => sub {
    my $self = shift;

    $self->ua->credentials($self->apihost, $self->apirealm, $self->username, $self->password);
};

base_url     'apiurl';
authenticate 1;

twitter_api_method public_timeline => (
    description => <<'EOT',
Returns the 20 most recent statuses from non-protected users who have
set a custom user icon.  Does not require authentication.  Note that
the public timeline is cached for 60 seconds so requesting it more
often than that is a waste of resources.

If user credentials are provided, C<public_timeline> calls are authenticated,
so they count against the authenticated user's rate limit.  Use C<<
->public_timeline({ authenticate => 0 }) >> to make an unauthenticated call
which will count against the calling IP address' rate limit, instead.
EOT

    path     => 'statuses/public_timeline',
    method   => 'GET',
    returns  => 'ArrayRef[Status]',
    params   => [],
    required => [],
);

twitter_api_method friends_timeline => (
    description => <<'',
Returns the 20 most recent statuses posted by the authenticating user
and that user's friends. This is the equivalent of /home on the Web.

    aliases   => [qw/following_timeline/],
    path      => 'statuses/friends_timeline',
    method    => 'GET',
    params    => [qw/since_id max_id count page/],
    required  => [],
    returns   => 'ArrayRef[Status]',
);

twitter_api_method user_timeline => (
    description => <<'',
Returns the 20 most recent statuses posted from the authenticating
user. It's also possible to request another user's timeline via the id
parameter. This is the equivalent of the Web /archive page for
your own user, or the profile page for a third party.

    path    => 'statuses/user_timeline/id',
    method  => 'GET',
    params  => [qw/id user_id screen_name since_id max_id count page/],
    required => [],
    returns => 'ArrayRef[Status]',
);

# TODO: URL should be 'mentions', not 'replies', but the Laconica API doesn't
# recognize 'mentions' yet, so we'll cheat, as long as Twitter plays along and
# keeps 'replies' active or until Laconica/Identica is fixed.
# (Fixed in Laconi.ca 0.7.4.)
twitter_api_method mentions => (
    description => <<'',
Returns the 20 most recent mentions (statuses containing @username) for the
authenticating user.

    aliases => [qw/replies/],
    path    => 'statuses/replies',
    method  => 'GET',
    params  => [qw/since_id max_id count page/],
    required => [],
    returns => 'ArrayRef[Status]',
);

twitter_api_method show_status => (
    description => <<'',
Returns a single status, specified by the id parameter.  The
status's author will be returned inline.

    path     => 'statuses/show/id',
    method   => 'GET',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'Status',
);

twitter_api_method update => (
    description => <<'',
Updates the authenticating user's status.  Requires the status parameter
specified.  A status update with text identical to the authenticating
user's current status will be ignored.

    path       => 'statuses/update',
    method     => 'POST',
    params     => [qw/status in_reply_to_status_id/],
    required   => [qw/status/],
    add_source => 1,
    returns    => 'Status',
);

twitter_api_method destroy_status => (
    description => <<'',
Destroys the status specified by the required ID parameter.  The
authenticating user must be the author of the specified status.

    path     => 'statuses/destroy/id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'Status',
);

twitter_api_method friends => (
    description => <<'EOT',
Returns the authenticating user's friends, each with current status
inline. They are ordered by the order in which they were added as
friends. It's also possible to request another user's recent friends
list via the id parameter.

Returns 100 friends per page.
EOT

    aliases  => [qw/following/],
    path     => 'statuses/friends/id',
    method   => 'GET',
    params   => [qw/id user_id screen_name page/],
    required => [qw//],
    returns  => 'ArrayRef[BasicUser]',
);

twitter_api_method followers => (
    description => <<'EOT',
Returns the authenticating user's followers, each with current status
inline.  They are ordered by the order in which they joined Twitter
(this is going to be changed).

Returns 100 followers per page.
EOT

    path     => 'statuses/followers/id',
    method   => 'GET',
    params   => [qw/id user_id screen_name page/],
    required => [qw//],
    returns  => 'ArrayRef[BasicUser]',
);

twitter_api_method show_user => (
    description => <<'',
Returns extended information of a given user, specified by ID or screen
name as per the required id parameter.  This information includes
design settings, so third party developers can theme their widgets
according to a given user's preferences. You must be properly
authenticated to request the page of a protected user.

    path     => 'users/show/id',
    method   => 'GET',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'ExtendedUser',
);

twitter_api_method direct_messages => (
    description => <<'',
Returns a list of the 20 most recent direct messages sent to the authenticating
user including detailed information about the sending and recipient users.

    path     => 'direct_messages',
    method   => 'GET',
    params   => [qw/since_id max_id count page/],
    required => [qw//],
    returns  => 'ArrayRef[DirectMessage]',
);

twitter_api_method sent_direct_messages => (
    description => <<'',
Returns a list of the 20 most recent direct messages sent by the authenticating
user including detailed information about the sending and recipient users.

    path     => 'direct_messages/sent',
    method   => 'GET',
    params   => [qw/since_id max_id page/],
    required => [qw//],
    returns  => 'ArrayRef[DirectMessage]',
);

twitter_api_method new_direct_message => (
    description => <<'',
Sends a new direct message to the specified user from the authenticating user.
Requires both the user and text parameters.  Returns the sent message when
successful.  In order to support numeric screen names, the C<screen_name> or
C<user_id> parameters may be used instead of C<user>.

    path     => 'direct_messages/new',
    method   => 'POST',
    params   => [qw/user text screen_name user_id/],
    required => [qw/user text/],
    returns  => 'DirectMessage',
);

twitter_api_method destroy_direct_message => (
    description => <<'',
Destroys the direct message specified in the required ID parameter.
The authenticating user must be the recipient of the specified direct
message.

    path     => 'direct_messages/destroy/id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'DirectMessage',
);

twitter_api_method show_friendship => (
    description => <<'',
Returns detailed information about the relationship between two users.

    aliases  => [qw/show_relationship/],
    path     => 'friendships/show',
    method   => 'GET',
    params   => [qw/source_id source_screen_name target_id target_id_name/],
    required => [qw/id/],
    returns  => 'Relationship',
);

twitter_api_method create_friend => (
    description => <<'',
Befriends the user specified in the ID parameter as the authenticating user.
Returns the befriended user when successful.  Returns a string describing the
failure condition when unsuccessful.

    aliases  => [qw/follow_new/],
    path     => 'friendships/create/id',
    method   => 'POST',
    params   => [qw/id user_id screen_name follow/],
    required => [qw/id/],
    returns  => 'BasicUser',
);

twitter_api_method destroy_friend => (
    description => <<'',
Discontinues friendship with the user specified in the ID parameter as the
authenticating user.  Returns the un-friended user when successful.
Returns a string describing the failure condition when unsuccessful.

    aliases  => [qw/unfollow/],
    path     => 'friendships/destroy/id',
    method   => 'POST',
    params   => [qw/id user_id screen_name/],
    required => [qw/id/],
    returns  => 'BasicUser',
);

twitter_api_method friendship_exists => (
    aliases     => [qw/relationship_exists follows/], # Net::Twitter
    description => <<'',
Tests for the existence of friendship between two users. Will return true if
user_a follows user_b, otherwise will return false.

    path     => 'friendships/exists',
    method   => 'GET',
    params   => [qw/user_a user_b/],
    required => [qw/user_a user_b/],
    returns  => 'Bool',
);

twitter_api_method friends_ids => (
    description => <<'EOT',
Returns an array of numeric IDs for every user the specified user is following.

Currently, Twitter returns IDs ordered from most recently followed to least
recently followed.  This order may change at any time.
EOT

    aliases  => [qw/following_ids/],
    path     => 'friends/ids/id',
    method   => 'GET',
    params   => [qw/id user_id screen_name page/],
    required => [qw/id/],
    returns  => 'ArrayRef[Int]',
);

twitter_api_method followers_ids => (
    description => <<'',
Returns an array of numeric IDs for every user is followed by.

    path     => 'followers/ids/id',
    method   => 'GET',
    params   => [qw/id user_id screen_name page/],
    required => [qw/id/],
    returns  => 'ArrayRef[Int]',
);

twitter_api_method verify_credentials => (
    description => <<'',
Returns an HTTP 200 OK response code and a representation of the
requesting user if authentication was successful; returns a 401 status
code and an error message if not.  Use this method to test if supplied
user credentials are valid.

    path     => 'account/verify_credentials',
    method   => 'GET',
    params   => [qw//],
    required => [qw//],
    returns  => 'ExtendedUser',
);

twitter_api_method end_session => (
    description => <<'',
Ends the session of the authenticating user, returning a null cookie.
Use this method to sign users out of client-facing applications like
widgets.

    path     => 'account/end_session',
    method   => 'POST',
    params   => [qw//],
    required => [qw//],
    returns  => 'Error', # HTTP Status: 200, error content. Silly!
);

twitter_api_method update_location => (
    description => <<'',
This method has been deprecated in favor of the update_profile method.
Its URL will continue to work, but please consider migrating to the newer
and more comprehensive method of updating profile attributes.

    deprecated  => 1,
    path     => 'account/update_location',
    method   => 'POST',
    params   => [qw/location/],
    required => [qw/location/],
    returns  => 'BasicUser',
);

twitter_api_method update_delivery_device => (
    description => <<'',
Sets which device Twitter delivers updates to for the authenticating
user.  Sending none as the device parameter will disable IM or SMS
updates.

    path     => 'account/update_delivery_device',
    method   => 'POST',
    params   => [qw/device/],
    required => [qw/device/],
    returns  => 'BasicUser',
);

twitter_api_method update_profile_colors => (
    description => <<'',
Sets one or more hex values that control the color scheme of the
authenticating user's profile page on twitter.com.  These values are
also returned in the /users/show API method.

    path     => 'account/update_profile_colors',
    method   => 'POST',
    params   => [qw/
        profile_background_color
        profile_text_color
        profile_link_color
        profile_sidebar_fill_color
        profile_sidebar_border_color
    /],
    required => [qw//],
    returns  => 'ExtendedUser',
);

twitter_api_method update_profile_image => (
    description => <<'',
Updates the authenticating user's profile image.  Expects raw multipart
data, not a URL to an image.

    path     => 'account/update_profile_image',
    method   => 'POST',
    params   => [qw/image/],
    required => [qw/image/],
    returns  => 'ExtendedUser',
);

twitter_api_method update_profile_background_image => (
    description => <<'',
Updates the authenticating user's profile background image.  Expects
raw multipart data, not a URL to an image.

    path     => 'account/update_profile_background_image',
    method   => 'POST',
    params   => [qw/image/],
    required => [qw/image/],
    returns  => 'ExtendedUser',
);

twitter_api_method rate_limit_status => (
    description => <<'EOT',
Returns the remaining number of API requests available to the
authenticated user before the API limit is reached for the current hour.

Use C<< ->rate_limit_status({ authenticate => 0 }) >> to force an
unauthenticated call, which will return the status for the IP address rather
than the authenticated user. (Note: for a web application, this is the server's
IP address.)
EOT

    path     => 'account/rate_limit_status',
    method   => 'GET',
    params   => [qw//],
    required => [qw//],
    returns  => 'RateLimitStatus',
);

twitter_api_method update_profile => (
    description => <<'',
Sets values that users are able to set under the "Account" tab of their
settings page. Only the parameters specified will be updated; to only
update the "name" attribute, for example, only include that parameter
in your request.

    path     => 'account/update_profile',
    method   => 'POST',
    params   => [qw/ name email url location description /],
    required => [qw//],
    returns  => 'ExtendedUser',
);

twitter_api_method favorites => (
    description => <<'',
Returns the 20 most recent favorite statuses for the authenticating
user or user specified by the ID parameter.

    path     => 'favorites/id',
    method   => 'GET',
    params   => [qw/id page/],
    required => [qw//],
    returns  => 'ArrayRef[Status]',
);

twitter_api_method create_favorite => (
    description => <<'',
Favorites the status specified in the ID parameter as the
authenticating user.  Returns the favorite status when successful.

    path     => 'favorites/create/id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'Status',
);

twitter_api_method destroy_favorite => (
    description => <<'',
Un-favorites the status specified in the ID parameter as the
authenticating user.  Returns the un-favorited status.

    path     => 'favorites/destroy/id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'Status',
);

twitter_api_method enable_notifications  => (
    description => <<'',
Enables notifications for updates from the specified user to the
authenticating user.  Returns the specified user when successful.

    path     => 'notifications/follow/id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'BasicUser',
);

twitter_api_method disable_notifications => (
    description => <<'',
Disables notifications for updates from the specified user to the
authenticating user.  Returns the specified user when successful.

    path     => 'notifications/leave/id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'BasicUser',
);

twitter_api_method create_block => (
    description => <<'',
Blocks the user specified in the ID parameter as the authenticating user.
Returns the blocked user when successful.  You can find out more about
blocking in the Twitter Support Knowledge Base.

    path     => 'blocks/create/id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'BasicUser',
);


twitter_api_method destroy_block => (
    description => <<'',
Un-blocks the user specified in the ID parameter as the authenticating user.
Returns the un-blocked user when successful.

    path     => 'blocks/destroy/id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'BasicUser',
);


twitter_api_method block_exists => (
    description => <<'',
Returns if the authenticating user is blocking a target user. Will return the blocked user's
object if a block exists, and error with HTTP 404 response code otherwise.

    path     => 'blocks/exists/id',
    method   => 'GET',
    params   => [qw/id user_id screen_name/],
    required => [qw/id/],
    returns  => 'BasicUser',
);


twitter_api_method blocking => (
    description => <<'',
Returns an array of user objects that the authenticating user is blocking.

    path     => 'blocks/blocking',
    method   => 'GET',
    params   => [qw/page/],
    required => [qw//],
    returns  => 'ArrayRef[BasicUser]',
);


twitter_api_method blocking_ids => (
    description => <<'',
Returns an array of numeric user ids the authenticating user is blocking.

    path     => 'blocks/blocking/ids',
    method   => 'GET',
    params   => [qw//],
    required => [qw//],
    returns  => 'ArrayRef[Int]',
);

twitter_api_method test => (
    description => <<'',
Returns the string "ok" status code.

    path     => 'help/test',
    method   => 'GET',
    params   => [qw//],
    required => [qw//],
    returns  => 'Str',
);

twitter_api_method downtime_schedule => (
    description => <<'',
Returns the same text displayed on L<http://twitter.com/home> when a
maintenance window is scheduled.

    deprecated => 1,
    path     => 'help/downtime_schedule',
    method   => 'GET',
    params   => [qw//],
    required => [qw//],
    returns  => 'Str',
);

twitter_api_method saved_searches => (
    description => <<'',
Returns the authenticated user's saved search queries.

    path     => 'saved_searches',
    method   => 'GET',
    params   => [],
    required => [],
    returns  => 'ArrayRef[SavedSearch]',
);

twitter_api_method show_saved_search => (
    description => <<'',
Retrieve the data for a saved search, by C<id>, owned by the authenticating user.

    path     => 'saved_searches/show/id',
    method   => 'GET',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'SavedSearch',
);

twitter_api_method show_saved_search => (
    description => <<'',
Retrieve the data for a saved search, by ID, owned by the authenticating user.

    path     => 'saved_searches/show/id',
    method   => 'GET',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'SavedSearch',
);

twitter_api_method create_saved_search => (
    description => <<'',
Creates a saved search for the authenticated user.

    path     => 'saved_searches/create',
    method   => 'POST',
    params   => [qw/query/],
    required => [qw/query/],
    returns  => 'SavedSearch',
);

twitter_api_method destroy_saved_search => (
    description => <<'',
Destroys a saved search. The search, specified by C<id>, must be owned
by the authenticating user.

    path     => 'saved_searches/destroy/id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'SavedSearch',
);

1;

__END__

=head1 NAME

Net::Twitter::Role::API::REST - A definition of the Twitter REST API as a Moose role

=head1 SYNOPSIS

  package My::Twitter;
  use Moose;
  with 'Net::Twitter::API::REST';

=head1 DESCRIPTION

B<Net::Twitter::Role::API::REST> provides definitions for all the Twitter REST API
methods.  Applying this role to any class provides methods for all of the
Twitter REST API methods.


=head1 AUTHOR

Marc Mims <marc@questright.com>

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
