package Net::Twitter::Lite::API::REST;

use Moose;
use Carp;

with 'Net::Twitter::Lite::API';

sub base_url { sub { shift->apiurl || 'http://twitter.com' } }

# Definition is stored as a sub in order to return a deep copy;
# we don't want the caller inadvertently changing the definition!

sub definition {[

    [ 'Status Methods' => [
        [ public_timeline => {
            description => <<'',
Returns the 20 most recent statuses from non-protected users who have
set a custom user icon.  Does not require authentication.  Note that
the public timeline is cached for 60 seconds so requesting it more
often than that is a waste of resources.

            path    => 'statuses/public_timeline',
            method  => 'GET',
            returns => 'ArrayRef[Status]',
            params  => [],
            required => [],
        }],


        [ friends_timeline => {
            description => <<'',
Returns the 20 most recent statuses posted by the authenticating user
and that user's friends. This is the equivalent of /home on the Web.

            aliases   => [qw/following_timeline/],
            path      => 'statuses/friends_timeline',
            method    => 'GET',
            params    => [qw/since_id max_id count page/],
            required  => [],
            returns   => 'ArrayRef[Status]',
        }],


        [ user_timeline => {
            description => <<'',
Returns the 20 most recent statuses posted from the authenticating
user. It's also possible to request another user's timeline via the id
parameter. This is the equivalent of the Web /archive page for
your own user, or the profile page for a third party.

            path    => 'statuses/user_timeline',
            method  => 'GET',
            params  => [qw/id user_id screen_name since_id max_id count page/],
            required => [],
            returns => 'ArrayRef[Status]',
        }],


        [ mentions => {
            description => <<'',
Returns the 20 most recent mentions (statuses containing @username) for the
authenticating user.

            aliases => [qw/replies/],
            path    => 'statuses/mentions',
            method  => 'GET',
            params  => [qw/since_id max_id count page/],
            required => [],
            returns => 'ArrayRef[Status]',
        }],


        [ show_status => {
            description => <<'',
Returns a single status, specified by the id parameter.  The
status's author will be returned inline.

            path     => 'statuses/show/id',
            method   => 'GET',
            params   => [qw/id/],
            required => [qw/id/],
            returns  => 'Status',
        }],


        [ update => {
            description => <<'',
Updates the authenticating user's status.  Requires the status parameter
specified.  A status update with text identical to the authenticating
user's current status will be ignored.

            path     => 'statuses/update',
            method   => 'POST',
            params   => [qw/status in_reply_to_status_id/],
            required => [qw/status/],
            returns  => 'Status',
        }],


        [ destroy_status => {
            description => <<'',
Destroys the status specified by the required ID parameter.  The
authenticating user must be the author of the specified status.

            path     => 'statuses/destroy/id',
            method   => 'POST',
            params   => [qw/id/],
            required => [qw/id/],
            returns  => 'Status',
        }],
    ]],

    [ 'User Methods' => [


        [ friends => {
            description => <<'',
Returns the authenticating user's friends, each with current status
inline. They are ordered by the order in which they were added as
friends. It's also possible to request another user's recent friends
list via the id parameter.

            aliases  => [qw/following/],
            path     => 'statuses/friends',
            method   => 'GET',
            params   => [qw/id user_id screen_name page/],
            required => [qw//],
            returns  => 'ArrayRef[BasicUser]',
        }],


        [ followers => {
            description => <<'',
Returns the authenticating user's followers, each with current status
inline.  They are ordered by the order in which they joined Twitter
(this is going to be changed).

            path     => 'statuses/followers',
            method   => 'GET',
            params   => [qw/id user_id screen_name page/],
            required => [qw//],
            returns  => 'ArrayRef[BasicUser]',
        }],


        [ show_user => {
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
        }],
    ]],


    [ 'Direct Message Methods' => [


        [ direct_messages => {
            description => <<'',
Returns a list of the 20 most recent direct messages sent to the authenticating
user including detailed information about the sending and recipient users.

            path     => 'direct_messages',
            method   => 'GET',
            params   => [qw/since_id max_id count page/],
            required => [qw//],
            returns  => 'ArrayRef[DirectMessage]',
        }],


        [ sent_direct_messages => {
            description => <<'',
Returns a list of the 20 most recent direct messages sent by the authenticating
user including detailed information about the sending and recipient users.

            path     => 'direct_messages/sent',
            method   => 'GET',
            params   => [qw/since_id max_id page/],
            required => [qw//],
            returns  => 'ArrayRef[DirectMessage]',
        }],


        [ new_direct_message => {
            description => <<'',
Sends a new direct message to the specified user from the authenticating user.
Requires both the user and text parameters.  Returns the sent message in the
requested format when successful.

            path     => 'direct_messages/new',
            method   => 'POST',
            params   => [qw/user text/],
            required => [qw/user text/],
            returns  => 'DirectMessage',
        }],


        [ destroy_direct_message => {
            description => <<'',
Destroys the direct message specified in the required ID parameter.
The authenticating user must be the recipient of the specified direct
message.

            path     => 'direct_messages/destroy/id',
            method   => 'POST',
            params   => [qw/id/],
            required => [qw/id/],
            returns  => 'DirectMessage',
        }],
    ]],


    [ 'Friendship Methods' => [


        [ create_friend => {
            description => <<'',
Befriends the user specified in the ID parameter as the authenticating
user.  Returns the befriended user in the requested format when
successful.  Returns a string describing the failure condition when
unsuccessful.

            alias    => [qw/follow_new/],
            path     => 'friendships/create/id',
            method   => 'POST',
            params   => [qw/id user_id screen_name follow/],
            required => [qw/id/],
            returns  => 'BasicUser',
        }],


        [ destroy_friend => {
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
        }],


        [ friendship_exists => {
            aliases     => [qw/relationship_exists follows/], # Net::Twitter
            description => <<'',
Tests if a friendship exists between two users.

            path     => 'friendships/exists',
            method   => 'GET',
            params   => [qw/user_a user_b/],
            required => [qw/user_a user_b/],
            returns  => 'Bool',
        }],
    ]],


    [ 'Social Graph Methods' => [


        [ friends_ids => {
            description => <<'',
Returns an array of numeric IDs for every user the specified user is following.

            aliases  => [qw/following_ids/],
            path     => 'friends/ids/id',
            method   => 'GET',
            params   => [qw/id user_id screen_name page/],
            required => [qw/id/],
            returns  => 'ArrayRef[Int]',
        }],


        [ followers_ids => {
            description => <<'',
Returns an array of numeric IDs for every user is followed by.

            path     => 'followers/ids/id',
            method   => 'GET',
            params   => [qw/id user_id screen_name page/],
            required => [qw/id/],
            returns  => 'ArrayRef[Int]',
        }],

    ]],


    [ 'Account Methods' => [
        [ verify_credentials => {
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
        }],


        [ end_session => {
            description => <<'',
Ends the session of the authenticating user, returning a null cookie.
Use this method to sign users out of client-facing applications like
widgets.

            path     => 'account/end_session',
            method   => 'POST',
            params   => [qw//],
            required => [qw//],
            returns  => 'Error', # HTTP Status: 200, error content. Silly!
        }],


        [ update_location => {
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
        }],


        [ update_delivery_device => {
            description => <<'',
Sets which device Twitter delivers updates to for the authenticating
user.  Sending none as the device parameter will disable IM or SMS
updates.

            path     => 'account/update_delivery_device',
            method   => 'POST',
            params   => [qw/device/],
            required => [qw/device/],
            returns  => 'BasicUser',
        }],


        [ update_profile_colors => {
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
        }],


        [ update_profile_image => {
            description => <<'',
Updates the authenticating user's profile image.  Expects raw multipart
data, not a URL to an image.

            path     => 'account/update_profile_image',
            method   => 'POST',
            params   => [qw/image/],
            required => [qw/image/],
            returns  => 'ExtendedUser',
        }],


        [ update_profile_background_image => {
            description => <<'',
Updates the authenticating user's profile background image.  Expects
raw multipart data, not a URL to an image.

            path     => 'account/update_profile_background_image',
            method   => 'POST',
            params   => [qw/image/],
            required => [qw/image/],
            returns  => 'ExtendedUser',
        }],


        [ rate_limit_status => {
            description => <<'',
Returns the remaining number of API requests available to the
requesting user before the API limit is reached for the current hour.
Calls to rate_limit_status do not count against the rate limit.  If
authentication credentials are provided, the rate limit status for the
authenticating user is returned.  Otherwise, the rate limit status for
the requester's IP address is returned.

            path     => 'account/rate_limit_status',
            method   => 'GET',
            params   => [qw//],
            required => [qw//],
            returns  => 'RateLimitStatus',
        }],


        [ update_profile => {
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
        }],
    ]],


    [ 'Favorite Methods' => [


        [ favorites => {
            description => <<'',
Returns the 20 most recent favorite statuses for the authenticating
user or user specified by the ID parameter.

            path     => 'favorites',
            method   => 'GET',
            params   => [qw/id page/],
            required => [qw//],
            returns  => 'ArrayRef[Status]',
        }],


        [ create_favorite => {
            description => <<'',
Favorites the status specified in the ID parameter as the
authenticating user.  Returns the favorite status when successful.

            path     => 'favorites/create/id',
            method   => 'POST',
            params   => [qw/id/],
            required => [qw/id/],
            returns  => 'Status',
        }],


        [ destroy_favorite => {
            description => <<'',
Un-favorites the status specified in the ID parameter as the
authenticating user.  Returns the un-favorited status.

            path     => 'favorites/destroy/id',
            method   => 'POST',
            params   => [qw/id/],
            required => [qw/id/],
            returns  => 'Status',
        }],
    ]],


    [ 'Notification Methods' => [


        [ enable_notifications  => {
            description => <<'',
Enables notifications for updates from the specified user to the
authenticating user.  Returns the specified user when successful.

            path     => 'notifications/follow/id',
            method   => 'POST',
            params   => [qw/id/],
            required => [qw/id/],
            returns  => 'BasicUser',
        }],



        [ disable_notifications => {
            description => <<'',
Disables notifications for updates from the specified user to the
authenticating user.  Returns the specified user when successful.

            path     => 'notifications/leave/id',
            method   => 'POST',
            params   => [qw/id/],
            required => [qw/id/],
            returns  => 'BasicUser',
        }],

    ]],


    [ 'Block Methods' => [


        [ create_block => {
            description => <<'',
Blocks the user specified in the ID parameter as the authenticating user.
Returns the blocked user when successful.  You can find out more about
blocking in the Twitter Support Knowledge Base.

            path     => 'blocks/create/id',
            method   => 'POST',
            params   => [qw/id/],
            required => [qw/id/],
            returns  => 'BasicUser',
        }],


        [ destroy_block => {
            description => <<'',
Un-blocks the user specified in the ID parameter as the authenticating user.
Returns the un-blocked user when successful.

            path     => 'blocks/destroy/id',
            method   => 'POST',
            params   => [qw/id/],
            required => [qw/id/],
            returns  => 'BasicUser',
        }],


        [ block_exists => {
            description => <<'',
Returns if the authenticating user is blocking a target user. Will return the blocked user's
object if a block exists, and error with HTTP 404 response code otherwise.

            path     => 'blocks/exists/id',
            method   => 'GET',
            params   => [qw/id user_id screen_name/],
            required => [qw/id/],
            returns  => 'BasicUser',
        }],


        [ blocking => {
            description => <<'',
Returns an array of user objects that the authenticating user is blocking.

            path     => 'blocks/blocking',
            method   => 'GET',
            params   => [qw/page/],
            required => [qw//],
            returns  => 'ArrayRef[BasicUser]',
        }],


        [ blocking_ids => {
            description => <<'',
Returns an array of numeric user ids the authenticating user is blocking.

            path     => 'blocks/ids',
            method   => 'GET',
            params   => [qw//],
            required => [qw//],
            returns  => 'ArrayRef[Int]',
        }],
    ]],

    [ 'Help Methods' => [

        [ test => {
            description => <<'',
Returns the string "ok" status code.

            path     => 'help/test',
            method   => 'GET',
            params   => [qw//],
            required => [qw//],
            returns  => 'Str',
        }],



        [ downtime_schedule => {
            description => <<'',
Returns the same text displayed on L<http://twitter.com/home> when a
maintenance window is scheduled.

            deprecated => 1,
            path     => 'help/downtime_schedule',
            method   => 'GET',
            params   => [qw//],
            required => [qw//],
            returns  => 'Str',
        }],

    ]],

]}

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Net::Twitter::Lite::API - A definition of the Twitter API in a perl data structure

=head1 SYNOPSIS

    use aliased 'Net::Twitter::Lite::API::REST';

    my $api_def = API->definition;

=head1 DESCRIPTION

B<Net::Twitter::Lite::API::REST> provides a perl data structure describing the
Twitter REST API.  It is used by the Net::Twitter::Lite distribution to
dynamically build methods, documentation, and tests.

=head1 METHODS

=over 4

=item base_url

Returns the base URL for the Twitter REST API.

=item definition

Returns a perl data structure describing the Twitter REST API.  See
L<Net::Twitter::Lite::API> for documentation on the data structure format.

=back

=head1 SEE ALSO

=over 4

=item L<Net::Twitter::Lite>

Net::Twitter::Lite::API was written for the use of this module and its distribution.

=item L<http://apiwiki.twitter.com/REST+API+Documentation>

The Twitter REST API documentation.

=back

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

Copyright (c) 2009 Marc Mims

The Twitter API itself, and the description text used in this module is:

Copyright (c) 2009 Twitter

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
