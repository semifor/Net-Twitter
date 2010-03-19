package Net::Twitter::Role::API::REST;
use Moose::Role;
use Net::Twitter::API;
use DateTime::Format::Strptime;

requires qw/ua username password credentials/;

my $build_api_host = sub {
    my $uri = URI->new(shift->apiurl);
    join ':', $uri->host, $uri->port;
};

has apiurl          => ( isa => 'Str', is => 'ro', default => 'http://api.twitter.com/1'  );
has apihost         => ( isa => 'Str', is => 'ro', lazy => 1, default => $build_api_host  );
has apirealm        => ( isa => 'Str', is => 'ro', default => 'Twitter API'               );

after BUILD => sub {
    my $self = shift;

    $self->{apiurl} =~ s/^http:/https:/ if $self->ssl;
};

around BUILDARGS => sub {
    my $next    = shift;
    my $class   = shift;

    my %options = @_ == 1 ? %{$_[0]} : @_;

    if ( delete $options{identica} ) {
        %options = (
            apiurl => 'http://identi.ca/api',
            apirealm => 'Laconica API',
            %options,
        );
    }

    return $next->($class, \%options);
};

after credentials => sub {
    my $self = shift;

    $self->ua->credentials($self->apihost, $self->apirealm, $self->username, $self->password);
};

base_url     'apiurl';
authenticate 1;

our $DATETIME_PARSER = DateTime::Format::Strptime->new(pattern => '%a %b %d %T %z %Y');
datetime_parser $DATETIME_PARSER;

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

twitter_api_method home_timeline => (
    description => <<'',
Returns the 20 most recent statuses, including retweets, posted by the
authenticating user and that user's friends. This is the equivalent of
/timeline/home on the Web.

    path      => 'statuses/home_timeline',
    method    => 'GET',
    params    => [qw/since_id max_id count page/],
    required  => [],
    returns   => 'ArrayRef[Status]',
);

twitter_api_method retweet => (
    description => <<'',
Retweets a tweet. Requires the id parameter of the tweet you are retweeting.
Returns the original tweet with retweet details embedded.

    path      => 'statuses/retweet/:id',
    method    => 'POST',
    params    => [qw/id/],
    required  => [qw/id/],
    returns   => 'Status',
);

twitter_api_method retweets => (
    description => <<'',
Returns up to 100 of the first retweets of a given tweet.

    path    => 'statuses/retweets/:id',
    method  => 'GET',
    params  => [qw/id count/],
    required => [qw/id/],
    returns  => 'Arrayref[Status]',
);

twitter_api_method retweeted_by_me => (
    description => <<'',
Returns the 20 most recent retweets posted by the authenticating user.

    path      => 'statuses/retweeted_by_me',
    method    => 'GET',
    params    => [qw/since_id max_id count page/],
    required  => [],
    returns   => 'ArrayRef[Status]',
);

twitter_api_method retweeted_to_me => (
    description => <<'',
Returns the 20 most recent retweets posted by the authenticating user's friends.

    path      => 'statuses/retweeted_to_me',
    method    => 'GET',
    params    => [qw/since_id max_id count page/],
    required  => [],
    returns   => 'ArrayRef[Status]',
);

twitter_api_method retweets_of_me => (
    description => <<'',
Returns the 20 most recent tweets of the authenticated user that have been
retweeted by others.

    aliases   => [qw/retweeted_of_me/],
    path      => 'statuses/retweets_of_me',
    method    => 'GET',
    params    => [qw/since_id max_id count page/],
    required  => [],
    returns   => 'ArrayRef[Status]',
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

    path    => 'statuses/user_timeline/:id',
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

    path     => 'statuses/show/:id',
    method   => 'GET',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'Status',
);

twitter_api_method update => (
    path       => 'statuses/update',
    method     => 'POST',
    params     => [qw/status lat long place_id display_coordinates in_reply_to_status_id/],
    required   => [qw/status/],
    booleans   => [qw/display_coordinates/],
    add_source => 1,
    returns    => 'Status',
    description => <<'EOT',

Updates the authenticating user's status.  Requires the status parameter
specified.  A status update with text identical to the authenticating
user's current status will be ignored.

=over 4

=item status

Required.  The text of your status update. URL encode as necessary. Statuses
over 140 characters will cause a 403 error to be returned from the API.

=item in_reply_to_status_id

Optional. The ID of an existing status that the update is in reply to.  o Note:
This parameter will be ignored unless the author of the tweet this parameter
references is mentioned within the status text. Therefore, you must include
@username, where username is the author of the referenced tweet, within the
update.

=item lat

Optional. The location's latitude that this tweet refers to.  The valid ranges
for latitude is -90.0 to +90.0 (North is positive) inclusive.  This parameter
will be ignored if outside that range, if it is not a number, if geo_enabled is
disabled, or if there not a corresponding long parameter with this tweet.

=item long

Optional. The location's longitude that this tweet refers to.  The valid ranges
for longitude is -180.0 to +180.0 (East is positive) inclusive.  This parameter
will be ignored if outside that range, if it is not a number, if geo_enabled is
disabled, or if there not a corresponding lat parameter with this tweet.

=item place_id

Optional. The place to attach to this status update.  Valid place_ids can be
found by querying C<reverse_geocode>.

=item display_coordinates

Optional. By default, geo-tweets will have their coordinates exposed in the
status object (to remain backwards compatible with existing API applications).
To turn off the display of the precise latitude and longitude (but keep the
contextual location information), pass C<display_coordinates => 0> on the
status update.

=back

EOT

);

twitter_api_method destroy_status => (
    description => <<'',
Destroys the status specified by the required ID parameter.  The
authenticating user must be the author of the specified status.

    path     => 'statuses/destroy/:id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'Status',
);

twitter_api_method friends => (
    description => <<'EOT',
Returns a reference to an array of the user's friends.  If C<id>, C<user_id>,
or C<screen_name> is not specified, the friends of the authenticating user are
returned.  The returned users are ordered from most recently followed to least
recently followed.

Use the optional C<cursor> parameter to retrieve users in pages of 100.  When
the C<cursor> parameter is used, the return value is a reference to a hash with
keys C<previous_cursor>, C<next_cursor>, and C<users>.  The value of C<users>
is a reference to an array of the user's friends. The result set isn't
guaranteed to be 100 every time as suspended users will be filtered out.  Set
the optional C<cursor> parameter to -1 to get the first page of users.  Set it
to the prior return's value of C<previous_cursor> or C<next_cursor> to page
forward or backwards.  When there are no prior pages, the value of
C<previous_cursor> will be 0.  When there are no subsequent pages, the value of
C<next_cursor> will be 0.
EOT

    aliases  => [qw/following/],
    path     => 'statuses/friends/:id',
    method   => 'GET',
    params   => [qw/id user_id screen_name cursor/],
    required => [qw//],
    returns  => 'Hashref|ArrayRef[User]',
);

twitter_api_method followers => (
    description => <<'EOT',
Returns a reference to an array of the user's followers.  If C<id>, C<user_id>,
or C<screen_name> is not specified, the followers of the authenticating user are
returned.  The returned users are ordered from most recently followed to least
recently followed.

Use the optional C<cursor> parameter to retrieve users in pages of 100.  When
the C<cursor> parameter is used, the return value is a reference to a hash with
keys C<previous_cursor>, C<next_cursor>, and C<users>.  The value of C<users>
is a reference to an array of the user's friends. The result set isn't
guaranteed to be 100 every time as suspended users will be filtered out.  Set
the optional C<cursor> parameter to -1 to get the first page of users.  Set it
to the prior return's value of C<previous_cursor> or C<next_cursor> to page
forward or backwards.  When there are no prior pages, the value of
C<previous_cursor> will be 0.  When there are no subsequent pages, the value of
C<next_cursor> will be 0.
EOT

    path     => 'statuses/followers/:id',
    method   => 'GET',
    params   => [qw/id user_id screen_name cursor/],
    required => [qw//],
    returns  => 'HashRef|ArrayRef[User]',
);

twitter_api_method show_user => (
    description => <<'',
Returns extended information of a given user, specified by ID or screen
name as per the required id parameter.  This information includes
design settings, so third party developers can theme their widgets
according to a given user's preferences. You must be properly
authenticated to request the page of a protected user.

    path     => 'users/show/:id',
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

    path     => 'direct_messages/destroy/:id',
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
    path     => 'friendships/create/:id',
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
    path     => 'friendships/destroy/:id',
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
Returns a reference to an array of numeric IDs for every user followed the
specified user.

Use the optional C<cursor> parameter to retrieve IDs in pages of 5000.  When
the C<cursor> parameter is used, the return value is a reference to a hash with
keys C<previous_cursor>, C<next_cursor>, and C<ids>.  The value of C<ids> is a
reference to an array of IDS of the user's friends. Set the optional C<cursor>
parameter to -1 to get the first page of IDs.  Set it to the prior return's
value of C<previous_cursor> or C<next_cursor> to page forward or backwards.
When there are no prior pages, the value of C<previous_cursor> will be 0.  When
there are no subsequent pages, the value of C<next_cursor> will be 0.
EOT

    aliases  => [qw/following_ids/],
    path     => 'friends/ids/:id',
    method   => 'GET',
    params   => [qw/id user_id screen_name cursor/],
    required => [qw/id/],
    returns  => 'HashRef|ArrayRef[Int]',
);

twitter_api_method followers_ids => (
    description => <<'EOT',
Returns a reference to an array of numeric IDs for every user following the
specified user.

Use the optional C<cursor> parameter to retrieve IDs in pages of 5000.  When
the C<cursor> parameter is used, the return value is a reference to a hash with
keys C<previous_cursor>, C<next_cursor>, and C<ids>.  The value of C<ids> is a
reference to an array of IDS of the user's followers. Set the optional C<cursor>
parameter to -1 to get the first page of IDs.  Set it to the prior return's
value of C<previous_cursor> or C<next_cursor> to page forward or backwards.
When there are no prior pages, the value of C<previous_cursor> will be 0.  When
there are no subsequent pages, the value of C<next_cursor> will be 0.
EOT

    path     => 'followers/ids/:id',
    method   => 'GET',
    params   => [qw/id user_id screen_name cursor/],
    required => [qw/id/],
    returns  => 'HashRef|ArrayRef[Int]',
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
    description => <<'EOT',
Updates the authenticating user's profile image.  The C<image> parameter is an
arrayref with the following interpretation:

  [ $file ]
  [ $file, $filename ]
  [ $file, $filename, Content_Type => $mime_type ]
  [ undef, $filename, Content_Type => $mime_type, Content => $raw_image_data ]

The first value of the array (C<$file>) is the name of a file to open.  The
second value (C<$filename>) is the name given to Twitter for the file.  If
C<$filename> is not provided, the basename portion of C<$file> is used.  If
C<$mime_type> is not provided, it will be provided automatically using
L<LWP::MediaTypes::guess_media_type()>.

C<$raw_image_data> can be provided, rather than opening a file, by passing
C<undef> as the first array value.
EOT

    path     => 'account/update_profile_image',
    method   => 'POST',
    params   => [qw/image/],
    required => [qw/image/],
    returns  => 'ExtendedUser',
);

twitter_api_method update_profile_background_image => (
    description => <<'',
Updates the authenticating user's profile background image. The C<image>
parameter must be an arrayref with the same interpretation as the C<image>
parameter in the C<update_profile_image> method.  See that method's
documentation for details.

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

    path     => 'favorites/:id',
    method   => 'GET',
    params   => [qw/id page/],
    required => [qw//],
    returns  => 'ArrayRef[Status]',
);

twitter_api_method create_favorite => (
    description => <<'',
Favorites the status specified in the ID parameter as the
authenticating user.  Returns the favorite status when successful.

    path     => 'favorites/create/:id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'Status',
);

twitter_api_method destroy_favorite => (
    description => <<'',
Un-favorites the status specified in the ID parameter as the
authenticating user.  Returns the un-favorited status.

    path     => 'favorites/destroy/:id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'Status',
);

twitter_api_method enable_notifications  => (
    description => <<'',
Enables notifications for updates from the specified user to the
authenticating user.  Returns the specified user when successful.

    path     => 'notifications/follow/:id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'BasicUser',
);

twitter_api_method disable_notifications => (
    description => <<'',
Disables notifications for updates from the specified user to the
authenticating user.  Returns the specified user when successful.

    path     => 'notifications/leave/:id',
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

    path     => 'blocks/create/:id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'BasicUser',
);


twitter_api_method destroy_block => (
    description => <<'',
Un-blocks the user specified in the ID parameter as the authenticating user.
Returns the un-blocked user when successful.

    path     => 'blocks/destroy/:id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'BasicUser',
);


twitter_api_method block_exists => (
    description => <<'',
Returns if the authenticating user is blocking a target user. Will return the blocked user's
object if a block exists, and error with HTTP 404 response code otherwise.

    path     => 'blocks/exists/:id',
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

    path     => 'saved_searches/show/:id',
    method   => 'GET',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'SavedSearch',
);

twitter_api_method show_saved_search => (
    description => <<'',
Retrieve the data for a saved search, by ID, owned by the authenticating user.

    path     => 'saved_searches/show/:id',
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

    path     => 'saved_searches/destroy/:id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'SavedSearch',
);

twitter_api_method report_spam => (
    description => <<'',
The user specified in the id is blocked by the authenticated user and reported as a spammer.

    path     => 'report_spam',
    method   => 'POST',
    params   => [qw/id user_id screen_name/],
    required => [qw/id/],
    returns  => 'User',
);

twitter_api_method users_search => (
    aliases     => [qw/find_people search_users/],
    path        => 'users/search',
    method      => 'GET',
    params      => [qw/q per_page page/],
    required    => [qw/q/],
    returns     => 'ArrayRef[Users]',
    description => <<'',
Run a search for users similar to Find People button on Twitter.com; the same
results returned by people search on Twitter.com will be returned by using this
API (about being listed in the People Search).  It is only possible to retrieve
the first 1000 matches from this API.

);

twitter_api_method trends_available => (
    path        => 'trends/available',
    method      => 'GET',
    params      => [qw/lat long/],
    required    => [],
    returns     => 'ArrayRef[Location]',
    description => <<EOT,
Returns the locations with trending topic information. The response is an
array of "locations" that encode the location's WOEID (a Yahoo!  Where On Earth
ID L<http://developer.yahoo.com/geo/geoplanet/>) and some other human-readable
information such as a the location's canonical name and country.

When the optional C<lat> and C<long> parameters are passed, the available trend
locations are sorted by distance from that location, nearest to farthest.

Use the WOEID returned in the location object to query trends for a specific
location.
EOT
);

twitter_api_method trends_location => (
    path        => 'trends/location',
    method      => 'GET',
    params      => [qw/woeid/],
    required    => [qw/woeid/],
    returns     => 'ArrayRef[Trend]',
    description => <<'',
Returns the top 10 trending topics for a specific location. The response is an
array of "trend" objects that encode the name of the trending topic, the query
parameter that can be used to search for the topic on Search, and the direct
URL that can be issued against Search.  This information is cached for five
minutes, and therefore users are discouraged from querying these endpoints
faster than once every five minutes.  Global trends information is also
available from this API by using a WOEID of 1.

);

twitter_api_method reverse_geocode => (
    path        => 'geo/reverse_geocode',
    method      => 'GET',
    params      => [qw/lat long accuracy granularity max_results/],
    required    => [qw/lat long/],
    returns     => 'HashRef',
    description => <<'EOT',

Search for places (cities and neighborhoods) that can be attached to a
statuses/update.  Given a latitude and a longitude, return a list of all the
valid places that can be used as a place_id when updating a status.
Conceptually, a query can be made from the user's location, retrieve a list of
places, have the user validate the location he or she is at, and then send the
ID of this location up with a call to statuses/update.

There are multiple granularities of places that can be returned --
"neighborhoods", "cities", etc.  At this time, only United States data is
available through this method. 

=over 4

=item lat

Required.  The latitude to query about.  Valid ranges are -90.0 to +90.0 (North
is positive) inclusive.

=item long

Required. The longitude to query about.  Valid ranges are -180.0 to +180.0
(East is positive) inclusive.

=item accuracy

Optional. A hint on the "region" in which to search.  If a number, then this is
a radius in meters, but it can also take a string that is suffixed with ft to
specify feet.  If this is not passed in, then it is assumed to be 0m.  If
coming from a device, in practice, this value is whatever accuracy the device
has measuring its location (whether it be coming from a GPS, WiFi
triangulation, etc.).

=item granularity

Optional.  The minimal granularity of data to return.  If this is not passed
in, then C<neighborhood> is assumed.  C<city> can also be passed.

=item max_results

Optional.  A hint as to the number of results to return.  This does not
guarantee that the number of results returned will equal max_results, but
instead informs how many "nearby" results to return.  Ideally, only pass in the
number of places you intend to display to the user here. 

=back

EOT
);

twitter_api_method geo_id => (
    path => 'geo/id/:id',
    method => 'GET',
    params => [qw/id/],
    required => [qw/id/],
    returns  => 'HashRef',
    description => <<'EOT',
Returns details of a place returned from the C<reverse_geocode> method.
EOT
);

twitter_api_method lookup_users => (
    path => 'users/lookup',
    method => 'GET',
    params => [qw/user_id screen_name/],
    required => [],
    returns => 'ArrayRef[User]',
    description => <<'EOT'
Return up to 20 users worth of extended information, specified by either ID,
screen name, or combination of the two. The author's most recent status (if the
authenticating user has permission) will be returned inline.  This method is
rate limited to 1000 calls per hour.

This method will accept user IDs or screen names as either a comma delimited
string, or as an ARRAY ref.  It will also accept arguments in the normal
HASHREF form or as a simple list of named arguments.  I.e., any of the
following forms are acceptable:

    $nt->lookup_users({ user_id => '1234,6543,3333' });
    $nt->lookup_users(user_id => '1234,6543,3333');
    $nt->lookup_users({ user_id => [ 1234, 6543, 3333 ] });
    $nt->lookup_users({ screen_name => 'fred,barney,wilma' });
    $nt->lookup_users(screen_name => ['fred', 'barney', 'wilma']);

    $nt->lookup_users(
        screen_name => ['fred', 'barney' ],
        user_id     => '4321,6789',
    );

EOT
);

twitter_api_method retweeted_by => (
    path => 'statuses/:id/retweeted_by',
    method => 'GET',
    params => [qw/id count page/],
    required => [qw/id/],
    returns  => 'ArrayRef[User]',
    description => <<''
Returns up to 100 users who retweeted the status identified by C<id>.

);

twitter_api_method retweeted_by_ids => (
    path     => 'statuses/:id/retweeted_by_ids',
    method   => 'GET',
    params   => [qw/id count page/],
    required => [qw/id/],
    returns  => 'ArrayRef[User]',
    description => <<''
Returns the IDs of up to 100 users who retweeted the status identified by C<id>.

);

around lookup_users => sub {
    my $orig = shift;
    my $self = shift;

    my $args = ref $_[-1] eq 'HASH' ? pop @_ : {};
    $args = { %$args, @_ };

    for ( qw/screen_name user_id/ ) {
        $args->{$_} = join(',' => @{ $args->{$_} }) if ref $args->{$_} eq 'ARRAY';
    }

    return $orig->($self, $args);
};

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
