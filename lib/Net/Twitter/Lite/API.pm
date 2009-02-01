package Net::Twitter::Lite::API;
#!/usr/bin/perl
use warnings;
use strict;
use Carp;


# Definitions stored as subs in order to return a deep copy;
# we don't want the caller inadvertently chnaging the definition!

my %api = (

######### REST API

    rest => { base_url => 'http://twitter.com', definition => sub{[

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
        }],


        [ friends_timeline => {
            description => <<'',
Returns the 20 most recent statuses posted by the authenticating user
and that user's friends. This is the equivalent of /home on the Web.

            path      => 'statuses/friends_timeline',
            method    => 'GET',
            api_limit => 1,
            params    => [qw/since since_id count page/],
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
            params  => [qw/id count since since_id/],
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


        [ replies  => {
            description => <<'',
Returns the 20 most recent @replies (status updates prefixed with
@username) for the authenticating user.

            path     => 'statuses/replies',
            method   => 'GET',
            params   => [qw/page since since_id/],
            required => [qw//],
            returns  => 'ArrayRef[Status]',
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

            path     => 'statuses/friends',
            method   => 'GET',
            params   => [qw/id page/],
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
            params   => [qw/id page/],
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
            params   => [qw/id email/],
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
            params   => [qw/since since_id/],
            required => [qw//],
            returns  => 'ArrayRef[DirectMessage]',
        }],


        [ sent_direct_messages => {
            description => <<'',
Returns a list of the 20 most recent direct messages sent by the authenticating
user including detailed information about the sending and recipient users.

            path     => 'direct_messages/sent',
            method   => 'GET',
            params   => [qw/since since_id page/],
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

            path     => 'friendships/create/id',
            method   => 'POST',
            params   => [qw/id follow/],
            required => [qw/id/],
            returns  => 'BasicUser',
        }],


        [ destroy_friend => {
            description => <<'',
Discontinues friendship with the user specified in the ID parameter as the
authenticating user.  Returns the un-friended user when successful.
Returns a string describing the failure condition when unsuccessful.

            path     => 'friendships/destroy/id',
            method   => 'POST',
            params   => [qw/id/],
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

    ]}},

######### Search API

    search => { base_url => 'http://search.twitter.com', definition => sub{[


    [ 'Search Methods' => [


        [ search => {
            description => <<'',
Returns tweets that match a specified query.  You can use a variety of search operators in your query.

            path     => 'search',
            method   => 'GET',
            params   => [qw/q lang rpp page since_id geocode show_user/],
            required => [qw/q/],
            returns  => 'ArrayRef[Status]',
        }],


        [ trends => {
            description => <<'',
Returns the top ten queries that are currently trending on Twitter.  The response includes the time of the request, the name of each trending topic, and the url to the Twitter Search results page for that topic.

            path     => 'trends',
            method   => 'GET',
            params   => [qw//],
            required => [qw//],
            returns  => 'ArrayRef[Query]',
        }],
    ]],
]}});

sub _default_api { 'rest' }

sub _api_component {
    my ($class, $component, $api_name) = @_;

    $api_name ||= $class->_default_api;
    my $api_entry = $api{lc $api_name} || croak "API $api_name does not exist";
    return $api_entry->{$component};
}

sub base_url {
    my ($class, $api_name) = @_;

    $class->_api_component('base_url', $api_name);
}

sub definition {
    my ($class, $api_name) = @_;

    $class->_api_component('definition', $api_name)->();
}

sub method_definitions {
    my ($class, $api) = @_;

    $api ||= $class->_default_api;

    return { map { $_->[0] => $_->[1] } map @{$_->[1]}, @{$class->definition($api)} };
}

1;

__END__

=head1 NAME

Net::Twitter::Lite::API - A definition of the Twitter API in a perl data structure

=head1 SYNOPSIS

    use aliased 'Net::Twitter::Lite::API';

    my $api_def = API->definition;

=head1 DESCRIPTION

B<Net::Twitter::Lite::API> provides a perl data structure describing the Twitter API.  It is used
by the Net::Twitter::Lite distribution to dynamically build methods, documentation, and tests.

=head1 METHODS

=head2 base_url($api_name)

=head2 definition_url($api_name)

The two class methods B<base_url> and B<definition> take a single, optional
argument, $api_name, which may be either C<REST> for the Twitter REST API, or
C<search> for the Twitter Search API.  If $api_name is not specified, it
defaults to C<REST>. (The $api_name argument is not case sensitive, so C<rest>,
and C<REST> both work.)

B<base_url> returns the the base portion of the URL for the methods in the
requested API. B<definition> returns a data structure describing the API methods
in the following form:


    ArrayRef[Section];

where,

    Section is an ARRAY ref: [  SectionName, ArrayRef[Method] ];

where,

    SectionName is a string containing the name of the section;

and,

    Method is an ARRAY ref: [ MethodName, HashRef[MethodDefinition] ];

where,

    MethodName is a string containing the same of the Twitter API method;

and,

    MethodDefinion as a HASH ref: {
        description => Str,
        path        => Str,
        params      => ArrayRef[Str],
        required    => ArrayRef[Str],
        returns     => Str,
        deprecated  => Bool,
    }

where,

=over 4

=item description

A string containing text describing the Twitter API call.  Descriptions were lifted, almost
verbatim, from the Twitter REST API Documentation page L<http://apiwiki.twitter.com/REST+API+Documentation>.

=item path

A string containing the path for the Twitter API excluding the leading slash and
the C<.format> suffix.

=item params

An ARRAY ref of all documented parameter names, if any.  Otherwise, an empty ARRAY ref.

=item required

An ARRAY ref of all required parameters if any.  Otherwise, an empty ARRAY ref.

=item returns

A string is pseudo L<Moose::Util::TypeConstraint> syntax.  For example, a return type of
C<ArrayRef[Status]> is an ARRAY ref of status structures as defined by Twitter.

=item deprecated

A bool indicating the Twitter API method has been deprecated.  This can can be
omitted for non-deprecated methods.

=back

=head2 method_definitions($api_name)

This method returns a HASH ref where the keys are method names and the values are individual
method definitions as described above for the API specified by the optional $api_name
argument.  If $api_name is not specified, it defaults to C<REST>.

=head1 SEE ALSO

=over 4

=item L<Net::Twitter::Lite>

Net::Twitter::Lite::API was written for the use of this module and its distribution.

=item L<http://apiwiki.twitter.com/REST+API+Documentation>

The Twitter REST API documentation.

=item L<http://apiwiki.twitter.com/Search+API+Documentation>

The Twitter Search API documentation

=back

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

Copyright (c) 2009 Marc Mims

The Twitter API itself, and the description text used in this module is:

Copyright (c) 2009 Twitter

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
