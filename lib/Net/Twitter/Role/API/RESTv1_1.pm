package Net::Twitter::Role::API::RESTv1_1;

use Moose::Role;
use Carp::Clan qw/^(?:Net::Twitter|Moose|Class::MOP)/;
use Net::Twitter::API;
use DateTime::Format::Strptime;
use URI;

with 'Net::Twitter::Role::API::UploadMedia';

# API v1.1 incorporates the Search and Upload APIs
excludes map "Net::Twitter::Role::$_", qw/API::Search API::Upload Net::Twitter::Role::RateLimit/;

has apiurl          => ( isa => 'Str', is => 'ro', default => 'http://api.twitter.com/1.1'  );
has apihost         => ( isa => 'Str', is => 'ro', lazy => 1, builder => '_build_apihost' );
has apirealm        => ( isa => 'Str', is => 'ro', default => 'Twitter API'               );

sub _build_apihost {
    my $uri = URI->new(shift->apiurl);
    join ':', $uri->host, $uri->port;
}

after BUILD => sub {
    my $self = shift;

    $self->{apiurl} =~ s/^http:/https:/ if $self->ssl;
};

base_url     'apiurl';
authenticate 1;

our $DATETIME_PARSER = DateTime::Format::Strptime->new(pattern => '%a %b %d %T %z %Y');
datetime_parser $DATETIME_PARSER;

twitter_api_method mentions => (
    description => <<'',
Returns the 20 most recent mentions (statuses containing @username) for the
authenticating user.

    aliases => [qw/replies mentions_timeline/],
    path    => 'statuses/mentions_timeline',
    method  => 'GET',
    params  => [qw/since_id max_id count trim_user include_entities contributor_details/],
    booleans => [qw/trim_user include_entities contributor_details/],
    required => [],
    returns => 'ArrayRef[Status]',
);

twitter_api_method user_timeline => (
    description => <<'',
Returns the 20 most recent statuses posted by the authenticating user, or the
user specified by C<screen_name> or C<user_id>.

    path     => 'statuses/user_timeline',
    method   => 'GET',
    params   => [qw/user_id screen_name since_id max_id count trim_user exclude_replies include_rts contributor_details/],
    booleans => [qw/trim_user exclude_replies include_rts contributor_details/],
    required => [],
    returns  => 'ArrayRef[Status]',
);

twitter_api_method home_timeline => (
    description => <<'',
Returns the 20 most recent statuses, including retweets, posted by the
authenticating user and that user's friends. 

    path      => 'statuses/home_timeline',
    method    => 'GET',
    params    => [qw/since_id max_id count exclude_replies contributor_details
                     include_entities trim_user/],
    booleans  => [qw/skip_user exclude_replies contributor_details include_rts include_entities
                  trim_user include_my_retweet/],
    required  => [],
    returns   => 'ArrayRef[Status]',
);

twitter_api_method friends_timeline => (
    description => <<'',
Returns the 20 most recent statuses, including retweets, posted by the
authenticating user and that user's friends. 

    path      => 'statuses/home_timeline',
    aliases   => [qw/following_timeline/],
    method    => 'GET',
    params    => [qw/since_id max_id count exclude_replies contributor_details
                     include_entities trim_user/],
    booleans  => [qw/skip_user exclude_replies contributor_details include_rts include_entities
                  trim_user include_my_retweet/],
    required  => [],
    returns   => 'ArrayRef[Status]',
    deprecated => sub { carp "$_[0] DEPRECATED: using home_timeline instead" },
);

twitter_api_method retweets => (
    description => <<'',
Returns up to 100 of the first retweets of a given tweet.

    path     => 'statuses/retweets/:id',
    method   => 'GET',
    params   => [qw/id count trim_user/],
    booleans => [qw/trim_user/],
    required => [qw/id/],
    returns  => 'Arrayref[Status]',
);

twitter_api_method show_status => (
    description => <<'',
Returns a single status, specified by the id parameter.  The
status's author will be returned inline.

    path     => 'statuses/show/:id',
    method   => 'GET',
    params   => [qw/id trim_user include_entities include_my_retweet/],
    booleans => [qw/trim_user include_entities include_my_retweet/],
    required => [qw/id/],
    returns  => 'Status',
);

twitter_api_method destroy_status => (
    description => <<'',
Destroys the status specified by the required ID parameter.  The
authenticating user must be the author of the specified status.

    path     => 'statuses/destroy/:id',
    method   => 'POST',
    params   => [qw/id trim_user/],
    booleans => [qw/trim_user/],
    required => [qw/id/],
    returns  => 'Status',
);

twitter_api_method update => (
    path       => 'statuses/update',
    method     => 'POST',
    params     => [qw/media_ids status lat long place_id display_coordinates in_reply_to_status_id trim_user/],
    required   => [qw/status/],
    booleans   => [qw/display_coordinates trim_user/],
    add_source => 1,
    returns    => 'Status',
    description => <<EOT,

Updates the authenticating user's status.  Requires the status parameter
specified.  A status update with text identical to the authenticating
user's current status will be ignored.

\=over 4

\=item status

Required.  The text of your status update. URL encode as necessary. Statuses
over 140 characters will cause a 403 error to be returned from the API.

\=item in_reply_to_status_id

Optional. The ID of an existing status that the update is in reply to.  o Note:
This parameter will be ignored unless the author of the tweet this parameter
references is mentioned within the status text. Therefore, you must include
\@username, where username is the author of the referenced tweet, within the
update.

\=item lat

Optional. The location's latitude that this tweet refers to.  The valid ranges
for latitude is -90.0 to +90.0 (North is positive) inclusive.  This parameter
will be ignored if outside that range, if it is not a number, if geo_enabled is
disabled, or if there not a corresponding long parameter with this tweet.

\=item long

Optional. The location's longitude that this tweet refers to.  The valid ranges
for longitude is -180.0 to +180.0 (East is positive) inclusive.  This parameter
will be ignored if outside that range, if it is not a number, if geo_enabled is
disabled, or if there not a corresponding lat parameter with this tweet.

\=item place_id

Optional. The place to attach to this status update.  Valid place_ids can be
found by querying C<reverse_geocode>.

\=item display_coordinates

Optional. By default, geo-tweets will have their coordinates exposed in the
status object (to remain backwards compatible with existing API applications).
To turn off the display of the precise latitude and longitude (but keep the
contextual location information), pass C<display_coordinates => 0> on the
status update.

\=back

EOT

);

twitter_api_method retweet => (
    description => <<'',
Retweets a tweet. 

    path      => 'statuses/retweet/:id',
    method    => 'POST',
    params    => [qw/idtrim_user/],
    booleans  => [qw/trim_user/],
    required  => [qw/id/],
    returns   => 'Status',
);

twitter_api_method update_with_media => (
    path        => 'statuses/update_with_media',
    method      => 'POST',
    params      => [qw/
        status media[] possibly_sensitive in_reply_to_status_id lat long place_id display_coordinates
    /],
    required    => [qw/status media[]/],
    booleans    => [qw/possibly_sensitive display_coordinates/],
    returns     => 'Status',
    description => <<'EOT',
Updates the authenticating user's status and attaches media for upload.

The C<media[]> parameter is an arrayref with the following interpretation:

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

The Tweet text will be rewritten to include the media URL(s), which will reduce
the number of characters allowed in the Tweet text. If the URL(s) cannot be
appended without text truncation, the tweet will be rejected and this method
will return an HTTP 403 error. 
EOT

);

twitter_api_method oembed => (
    description => <<'EOT',
Returns information allowing the creation of an embedded representation of a
Tweet on third party sites. See the L<oEmbed|http://oembed.com/> specification
for information about the response format.

While this endpoint allows a bit of customization for the final appearance of
the embedded Tweet, be aware that the appearance of the rendered Tweet may
change over time to be consistent with Twitter's L<Display
Requirements|https://dev.twitter.com/terms/display-requirements>. Do not rely
on any class or id parameters to stay constant in the returned markup.

EOT

    method   => 'GET',
    path     => 'statuses/oembed',
    params   => [qw/id url maxwidth hide_media hide_thread omit_script align related lang/],
    required => [qw//],
    booleans => [qw/hide_media hide_thread omit_script/],
    returns  => 'Status',
);

twitter_api_method retweeters_ids => (
    description => <<'EOT',
Returns a collection of up to 100 user IDs belonging to users who have
retweeted the tweet specified by the id parameter.

This method offers similar data to C<retweets> and replaces API v1's
C<retweeted_by_ids> method.
EOT
    method   => 'GET',
    path     => 'statuses/retweeters/ids',
    params   => [qw/id cursor stringify_ids/],
    required => [qw/id/],
    booleans => [qw/stringify_ids/],
    returns  => 'HashRef',
);

twitter_api_method search => (
    description => <<'EOT',
Returns a HASH reference with some meta-data about the query including the
C<next_page>, C<refresh_url>, and C<max_id>. The statuses are returned in
C<results>.  To iterate over the results, use something similar to:

    my $r = $nt->search($search_term);
    for my $status ( @{$r->{statuses}} ) {
        print "$status->{text}\n";
    }
EOT

    path     => 'search/tweets',
    method   => 'GET',
    params   => [qw/q count callback lang locale rpp since_id max_id until geocode result_type include_entities/],
    required => [qw/q/],
    booleans => [qw/include_entities/],
    returns  => 'HashRef',
);

twitter_api_method direct_messages => (
    description => <<'EOT',
Returns a list of the 20 most recent direct messages sent to the authenticating
user including detailed information about the sending and recipient users.

Important: this method requires an access token with RWD (read, write, and
direct message) permissions.
EOT

    path     => 'direct_messages',
    method   => 'GET',
    params   => [qw/since_id max_id count page include_entities skip_status/],
    required => [],
    booleans => [qw/include_entities skip_status/],
    returns  => 'ArrayRef[DirectMessage]',
);

twitter_api_method sent_direct_messages => (
    description => <<'EOT',
Returns a list of the 20 most recent direct messages sent by the authenticating
user including detailed information about the sending and recipient users.

Important: this method requires an access token with RWD (read, write, and
direct message) permissions.
EOT

    aliases  => [qw/direct_messages_sent/],
    path     => 'direct_messages/sent',
    method   => 'GET',
    params   => [qw/since_id max_id page count include_entities/],
    booleans => [qw/include_entities/],
    required => [qw//],
    returns  => 'ArrayRef[DirectMessage]',
);

twitter_api_method show_direct_message => (
    description => <<'EOT',
Returns a single direct message, specified by an id parameter. Like
the C<direct_messages> request, this method will include the
user objects of the sender and recipient.  Requires authentication.

Important: this method requires an access token with RWD (read, write, and
direct message) permissions.
EOT

    path     => 'direct_messages/show',
    method   => 'GET',
    params   => [qw/id/],
    booleans => [],
    required => [qw/id/],
    returns  => 'HashRef',
);

twitter_api_method destroy_direct_message => (
    description => <<'EOT',
Destroys the direct message specified in the required ID parameter.
The authenticating user must be the recipient of the specified direct
message.

Important: this method requires an access token with RWD (read, write, and
direct message) permissions.
EOT

    path     => 'direct_messages/destroy',
    method   => 'POST',
    params   => [qw/id include_entities/],
    booleans => [qw/include_entities/],
    required => [qw/id/],
    returns  => 'DirectMessage',
);

twitter_api_method new_direct_message => (
    description => <<'EOT',
Sends a new direct message to the specified user from the authenticating user.
Requires both the user and text parameters.  Returns the sent message when
successful.  In order to support numeric screen names, the C<screen_name> or
C<user_id> parameters may be used instead of C<user>.

Important: this method requires an access token with RWD (read, write, and
direct message) permissions.
EOT

    path     => 'direct_messages/new',
    method   => 'POST',
    params   => [qw/user_id screen_name text/],
    booleans => [qw//],
    required => [qw/text/],
    returns  => 'DirectMessage',
);

around new_direct_message => sub {
    my $orig = shift;
    my $self = shift;

    my $args = ref $_[-1] eq ref {} ? pop : {};
    $args->{user} = shift unless exists $args->{user} || exists $args->{screen_name} || exists $args->{user_id};
    $args->{text} = shift unless exists $args->{text};

    croak "too many args" if @_;

    if ( my $user = delete $args->{user} ) {
        warn "user argument to new_direct_message deprecated; use screen_name or user_id";

        if ( $user =~ /^\d+$/ ) {
            $args->{user_id} = $user;
        }
        else {
            $args->{screen_name} = $user;
        }
    }

    return $self->$orig($args);
};

twitter_api_method friends_ids => (
    description => <<'EOT',
Returns a reference to an array of numeric IDs for every user followed by the
specified user. The order of the IDs is reverse chronological.

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
    path     => 'friends/ids',
    method   => 'GET',
    params   => [qw/user_id screen_name cursor stringify_ids/],
    required => [qw//],
    booleans => [qw/stringify_ids/],
    returns  => 'HashRef|ArrayRef[Int]',
);

twitter_api_method followers => (
    description => <<'',
Returns a cursored collection of user objects for users following the specified user.

    aliases => [qw/followers_list/],
    path    => 'followers/list',
    method  => 'GET',
    params  => [qw/user_id screen_name cursor/],
    required => [qw//],
    returns => 'HashRef',
);

twitter_api_method friends => (
    description => <<'',
Returns a cursored collection of user objects for users followed by the specified user.

    aliases => [qw/friends_list/],
    path    => 'friends/list',
    method  => 'GET',
    params  => [qw/user_id screen_name cursor/],
    required => [qw//],
    returns => 'HashRef',
);

twitter_api_method followers_ids => (
    description => <<'EOT',
Returns a reference to an array of numeric IDs for every user following the
specified user. The order of the IDs may change from call to call. To obtain
the screen names, pass the arrayref to L</lookup_users>.

Use the optional C<cursor> parameter to retrieve IDs in pages of 5000.  When
the C<cursor> parameter is used, the return value is a reference to a hash with
keys C<previous_cursor>, C<next_cursor>, and C<ids>.  The value of C<ids> is a
reference to an array of IDS of the user's followers. Set the optional C<cursor>
parameter to -1 to get the first page of IDs.  Set it to the prior return's
value of C<previous_cursor> or C<next_cursor> to page forward or backwards.
When there are no prior pages, the value of C<previous_cursor> will be 0.  When
there are no subsequent pages, the value of C<next_cursor> will be 0.
EOT

    path     => 'followers/ids',
    method   => 'GET',
    params   => [qw/user_id screen_name cursor/],
    params   => [qw/user_id screen_name cursor stringify_ids/],
    required => [qw//],
    booleans => [qw/stringify_ids/],
    returns  => 'HashRef|ArrayRef[Int]',
);

twitter_api_method lookup_friendships => (
    path        => 'friendships/lookup',
    method      => 'GET',
    params      => [qw/user_id screen_name/],
    required    => [],
    returns     => 'ArrayRef',
    description => <<''
Returns the relationship of the authenticating user to the comma separated list
or ARRAY ref of up to 100 screen_names or user_ids provided. Values for
connections can be: following, following_requested, followed_by, none.
Requires authentication.

);

twitter_api_method friendships_incoming => (
    description => <<'EOT',
Returns an HASH ref with an array of numeric IDs in the C<ids> element for
every user who has a pending request to follow the authenticating user.
EOT

    aliases  => [qw/incoming_friendships/],
    path     => 'friendships/incoming',
    method   => 'GET',
    params   => [qw/cursor stringify_ids/],
    required => [],
    booleans => [qw/stringify_ids/],
    returns  => 'HashRef',
);

twitter_api_method friendships_outgoing => (
    description => <<'EOT',
Returns an HASH ref with an array of numeric IDs in the C<ids> element for
every protected user for whom the authenticating user has a pending follow
request.
EOT

    aliases  => [qw/outgoing_friendships/],
    path => 'friendships/outgoing',
    method => 'GET',
    params   => [qw/cursor stringify_ids/],
    required => [],
    booleans => [qw/stringify_ids/],
    returns  => 'HashRef',

);

twitter_api_method create_friend => (
    description => <<'',
Follows the user specified in the C<user_id> or C<screen_name> parameter as the
authenticating user.  Returns the befriended user when successful.  Returns a
string describing the failure condition when unsuccessful.

    aliases  => [qw/follow follow_new create_friendship/],
    path     => 'friendships/create',
    method   => 'POST',
    params   => [qw/user_id screen_name follow/],
    booleans => [qw/follow/],
    required => [qw//],
    returns  => 'BasicUser',
);

twitter_api_method destroy_friend => (
    description => <<'',
Discontinues friendship with the user specified in the C<user_id> or
C<screen_name> parameter as the authenticating user.  Returns the un-friended
user when successful.  Returns a string describing the failure condition when
unsuccessful.

    aliases  => [qw/unfollow destroy_friendship/],
    path     => 'friendships/destroy',
    method   => 'POST',
    params   => [qw/user_id screen_name/],
    booleans => [qw//],
    required => [qw/id/],
    returns  => 'BasicUser',
);

twitter_api_method update_friendship => (
    path        => 'friendships/update',
    method      => 'POST',
    params      => [qw/user_id screen_name device retweets/],
    required    => [qw//],
    booleans    => [qw/device retweets/],
    returns     => 'HashRef',
    description => <<''
Allows you enable or disable retweets and device notifications from the
specified user. All other values are assumed to be false.  Requires
authentication.

);

twitter_api_method show_friendship => (
    description => <<'',
Returns detailed information about the relationship between two users.

    aliases  => [qw/show_relationship/],
    path     => 'friendships/show',
    method   => 'GET',
    params   => [qw/source_id source_screen_name target_id target_screen_name/],
    required => [qw//],
    returns  => 'Relationship',
);

# infer source and target from positional args for convenience
around show_friendship => sub {
    my $orig = shift;
    my $self = shift;

    my $args = ref $_[-1] eq ref {} ? pop : {};
    if ( @_ == 2 ) {
        for ( qw/source target/ ) {
            my $id = shift;
            $$args{$id =~ /^\d+$/ ? "${_}_id" : "${_}_screen_name"} = $id;
        }
    }
    return $self->$orig(@_, $args);
};

# provided for backwards compatibility
twitter_api_method friendship_exists => (
    description => <<'EOT',
This method is provided for backwards compatibility with Twitter API V1.0.
Twitter API V1.1 does not provide an endpoint for this call. Instead,
C<show_friendship> is called, the result is inspected, and an appropriate value
is returned which can be evaluated in a boolean context.

Tests for the existence of friendship between two users. Will return true if
user_a follows user_b, otherwise will return false.

Use of C<user_a> and C<user_b> is deprecated.  It has been preserved for backwards
compatibility, and is used for the two-argument positional form:

    $nt->friendship_exists($user_a, $user_b);

Instead, you should use one of the named argument forms:

    $nt->friendship_exists({ user_id_a => $id1, user_id_b => $id2 });
    $nt->friendship_exists({ screen_name_a => $name1, screen_name_b => $name2 });

Consider using C<show_friendship> instead.
EOT

    aliases  => [qw/relationship_exists follows/],
    path     => 'friendships/show',
    method   => 'GET',
    params   => [qw/user_id_a user_id_b screen_name_a screen_name_b user_a user_b/],
    required => [qw/user_a user_b/],
    returns  => 'Bool',
    deprecated => sub { carp "$_[0] DEPRECATED: using show_friendship instead" },
);

around [qw/friendship_exists relationship_exists follows/] => sub {
    my $orig = shift;
    my $self = shift;

    my $args = ref $_[-1] eq ref {} ? pop : {};
    my ( $user_a, $user_b ) = @_; # default ags, if they exist
    if ( $user_a ||= delete $$args{user_a} ) {
        if ( $user_a =~ /^\d+$/ ) {
            $$args{source_id} = $user_a;
        }
        else {
            $$args{source_screen_name} = $user_a;
        }
    }
    elsif ( $user_a = delete $$args{screen_name_a} ) {
        $$args{source_screen_name} = $user_a;
    }
    elsif ( $user_a = delete $$args{user_id_a} ) {
        $$args{source_user_id} = $user_a;
    }
    else {
        croak "source user not specified";
    }

    if ( $user_b ||= delete $$args{user_b} ) {
        if ( $user_b =~ /^\d+$/ ) {
            $$args{target_id} = $user_b;
        }
        else {
            $$args{target_screen_name} = $user_b;
        }
    }
    elsif ( $user_b = delete $$args{screen_name_b} ) {
        $$args{target_screen_name} = $user_b;
    }
    elsif ( $user_b = delete $$args{user_id_b} ) {
        $$args{target_user_id} = $user_b;
    }
    else {
        croak "target user not specified";
    }

    my $r = $self->$orig($args);
    return !!$$r{relationship}{target}{followed_by};
};

twitter_api_method account_settings => (
    description => <<'',
Returns the current trend, geo and sleep time information for the
authenticating user.

    path => 'account/settings',
    method      => 'GET',
    params      => [],
    required    => [],
    returns     => 'HashRef',
);

twitter_api_method verify_credentials => (
    description => <<'',
Returns an HTTP 200 OK response code and a representation of the
requesting user if authentication was successful; returns a 401 status
code and an error message if not.  Use this method to test if supplied
user credentials are valid.

    path     => 'account/verify_credentials',
    method   => 'GET',
    params   => [qw/include_entities skip_status/],
    booleans => [qw/include_entities skip_status/],
    required => [qw//],
    returns  => 'ExtendedUser',
);

twitter_api_method update_account_settings => (
    description => <<'',
Updates the authenticating user's settings.

    path => 'account/settings',
    method      => 'POST',
    params      => [qw/trend_location_woid sleep_time_enabled start_sleep_time end_sleep_time time_zone lang/],
    required    => [],
    booleans    => [qw/sleep_time_enabled/],
    returns     => 'HashRef',
);

twitter_api_method update_delivery_device => (
    description => <<'',
Sets which device Twitter delivers updates to for the authenticating user.
Sending none as the device parameter will disable SMS updates.

    path     => 'account/update_delivery_device',
    method   => 'POST',
    params   => [qw/device include_entities/],
    required => [qw/device/],
    booleans => [qw/include_entities/],
    returns  => 'BasicUser',
);

twitter_api_method update_profile => (
    description => <<'',
Sets values that users are able to set under the "Account" tab of their
settings page. Only the parameters specified will be updated; to only
update the "name" attribute, for example, only include that parameter
in your request.

    path     => 'account/update_profile',
    method   => 'POST',
    params   => [qw/name url location description include_entities skip_status/],
    required => [qw//],
    booleans => [qw/include_entities skip_status/],
    returns  => 'ExtendedUser',
);

twitter_api_method update_location => (
    description => <<'',
This method has been deprecated in favor of the update_profile method.
Its URL will continue to work, but please consider migrating to the newer
and more comprehensive method of updating profile attributes.

    path       => 'account/update_profile',
    method     => 'POST',
    params     => [qw/location/],
    required   => [qw/location/],
    returns    => 'BasicUser',
    deprecated => sub { carp "$_[0] DEPRECATED: using update_profile instead" },
);

twitter_api_method update_profile_background_image => (
    description => <<'',
Updates the authenticating user's profile background image. The C<image>
parameter must be an arrayref with the same interpretation as the C<image>
parameter in the C<update_profile_image> method. See that method's
documentation for details. The C<use> parameter allows you to specify whether
to use the uploaded profile background or not.

    path     => 'account/update_profile_background_image',
    method   => 'POST',
    params   => [qw/image tile include_entities skip_status use/],
    required => [qw//],
    booleans => [qw/include_entities skip_status use/],
    returns  => 'ExtendedUser',
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
        include_entities
        skip_status
    /],
    required => [qw//],
    booleans => [qw/include_entities skip_status/],
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
    params   => [qw/image include_entities skip_status/],
    required => [qw/image/],
    booleans => [qw/include_entities skip_status/],
    returns  => 'ExtendedUser',
);

twitter_api_method blocking => (
    description => <<'',
Returns an array of user objects that the authenticating user is blocking.

    path     => 'blocks/list',
    aliases  => [qw/blocks_list/],
    method   => 'GET',
    params   => [qw/cursor include_entities skip_status/],
    required => [qw//],
    returns  => 'ArrayRef[BasicUser]',
);

twitter_api_method blocking_ids => (
    description => <<'',
Returns an array of numeric user ids the authenticating user is blocking.

    path     => 'blocks/ids',
    aliases  => [qw/blocks_ids/],
    method   => 'GET',
    params   => [qw/cursor stringify_ids/],
    required => [qw//],
    booleans => [qw/stringify_ids/],
    returns  => 'ArrayRef[Int]',
);

twitter_api_method create_block => (
    description => <<'',
Blocks the user specified in the C<user_id> or C<screen_name> parameter as the
authenticating user.  Returns the blocked user when successful.  You can find
out more about blocking in the Twitter Support Knowledge Base.

    path     => 'blocks/create',
    method   => 'POST',
    params   => [qw/user_id screen_name include_entities skip_status/],
    booleans => [qw/include_entities skip_status/],    
    required => [qw/id/],
    returns  => 'BasicUser',
);

twitter_api_method destroy_block => (
    description => <<'',
Un-blocks the user specified in the C<user_id> or C<screen_name> parameter as
the authenticating user.  Returns the un-blocked user when successful.

    path     => 'blocks/destroy',
    method   => 'POST',
    params   => [qw/user_id screen_name include_entities skip_status/],
    booleans => [qw/include_entities skip_status/],
    required => [qw/id/],
    returns  => 'BasicUser',
);

twitter_api_method lookup_users => (
    description => <<'EOT',
Return up to 100 users worth of extended information, specified by either ID,
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

    path => 'users/lookup',
    method => 'GET',
    params => [qw/user_id screen_name include_entities/],
    booleans => [qw/include_entities/],
    required => [],
    returns => 'ArrayRef[User]',
);

twitter_api_method show_user => (
    description => <<'',
Returns extended information of a given user, specified by ID or screen
name as per the required id parameter.  This information includes
design settings, so third party developers can theme their widgets
according to a given user's preferences. You must be properly
authenticated to request the page of a protected user.

    path     => 'users/show',
    method   => 'GET',
    params   => [qw/user_id screen_name include_entities/],
    booleans => [qw/include_entities/],
    required => [qw//],
    returns  => 'ExtendedUser',
);

twitter_api_method users_search => (
    description => <<'',
Run a search for users similar to Find People button on Twitter.com; the same
results returned by people search on Twitter.com will be returned by using this
API (about being listed in the People Search).  It is only possible to retrieve
the first 1000 matches from this API.

    aliases     => [qw/find_people search_users/],
    path        => 'users/search',
    method      => 'GET',
    params      => [qw/q per_page page count include_entities/],
    booleans    => [qw/include_entities/],
    required    => [qw/q/],
    returns     => 'ArrayRef[Users]',
);

twitter_api_method contributees => (
    path        => 'users/contributees',
    method      => 'GET',
    params      => [qw/user_id screen_name include_entities skip_satus/],
    required    => [],
    booleans    => [qw/include_entities skip_satus/],
    returns     => 'ArrayRef[User]',
    description => <<'',
Returns an array of users that the specified user can contribute to.

);

twitter_api_method contributors => (
    path        => 'users/contributors',
    method      => 'GET',
    params      => [qw/user_id screen_name include_entities skip_satus/],
    required    => [],
    booleans    => [qw/include_entities skip_satus/],
    returns     => 'ArrayRef[User]',
    description => <<'',
Returns an array of users who can contribute to the specified account.

);

twitter_api_method suggestion_categories => (
    path        => 'users/suggestions',
    method      => 'GET',
    params      => [],
    required    => [],
    returns     => 'ArrayRef',
    description => <<''
Returns the list of suggested user categories. The category slug can be used in
the C<user_suggestions> API method get the users in that category .  Does not
require authentication.

);

twitter_api_method user_suggestions_for => (
    aliases     => [qw/follow_suggestions/],
    path        => 'users/suggestions/:category',
    method      => 'GET',
    params      => [qw/category lang/],
    required    => [qw/category/],
    returns     => 'ArrayRef',
    description => <<''
Access the users in a given category of the Twitter suggested user list.

);

twitter_api_method user_suggestions => (
    aliases     => [qw/follow_suggestions/],
    path        => 'users/suggestions/:category/members',
    method      => 'GET',
    params      => [qw/category lang/],
    required    => [qw/category/],
    returns     => 'ArrayRef',
    description => <<''
Access the users in a given category of the Twitter suggested user list and
return their most recent status if they are not a protected user. Currently
supported values for optional parameter C<lang> are C<en>, C<fr>, C<de>, C<es>,
C<it>.  Does not require authentication.

);

twitter_api_method favorites => (
    description => <<'',
Returns the 20 most recent favorite statuses for the authenticating
user or user specified by the ID parameter.

    path     => 'favorites/list',
    method   => 'GET',
    params   => [qw/user_id screen_name count since_id max_id include_entities/],
    booleans => [qw/include_entities/],
    required => [qw//],
    returns  => 'ArrayRef[Status]',
);

twitter_api_method destroy_favorite => (
    description => <<'',
Un-favorites the status specified in the ID parameter as the
authenticating user.  Returns the un-favorited status.

    path     => 'favorites/destroy',
    method   => 'POST',
    params   => [qw/id include_entities/],
    booleans => [qw/include_entities/],
    required => [qw/id/],
    returns  => 'Status',
);

twitter_api_method create_favorite => (
    description => <<'',
Favorites the status specified in the ID parameter as the
authenticating user.  Returns the favorite status when successful.

    path     => 'favorites/create',
    method   => 'POST',
    params   => [qw/id include_entities/],
    booleans => [qw/include_entities/],
    required => [qw/id/],
    returns  => 'Status',
);

### Lists ###

twitter_api_method get_lists => (
    description => <<'EOT',
Returns all lists the authenticating or specified user subscribes to, including
their own. The user is specified using the user_id or screen_name parameters.
If no user is given, the authenticating user is used.

A maximum of 100 results will be returned by this call. Subscribed lists are
returned first, followed by owned lists. This means that if a user subscribes
to 90 lists and owns 20 lists, this method returns 90 subscriptions and 10
owned lists. The reverse method returns owned lists first, so with C<reverse =>
1>, 20 owned lists and 80 subscriptions would be returned. If your goal is to
obtain every list a user owns or subscribes to, use <list_ownerships> and/or
C<list_subscriptions> instead.
EOT

    path        => 'lists/list',
    aliases     => [qw/list_lists all_subscriptions/],
    method      => 'GET',
    params      => [qw/user_id screen_name reverse/],
    required    => [],
    returns     => 'Hashref',
);

twitter_api_method list_statuses => (
    description => <<'',
Returns tweet timeline for members of the specified list. Historically,
retweets were not available in list timeline responses but you can now use the
include_rts=true parameter to additionally receive retweet objects.

    path        => 'lists/statuses',
    method      => 'GET',
    params      => [qw/
        list_id slug owner_screen_name owner_id since_id max_id count
        include_entities include_rts
    /],
    required    => [],
    booleans    => [qw/include_entities include_rts/],
    returns     => 'ArrayRef[Status]',
);

twitter_api_method delete_list_member => (
    description => <<'',
Removes the specified member from the list. The authenticated user must be the
list's owner to remove members from the list.

    path        => 'lists/members/destroy',
    method      => 'POST',
    params      => [qw/list_id slug user_id screen_name owner_screen_name owner_id/],
    required    => [],
    returns     => 'User',
    aliases     => [qw/remove_list_member/],
);

twitter_api_method list_memberships => (
    description => <<'',
Returns the lists the specified user has been added to. If user_id or
screen_name are not provided the memberships for the authenticating user are
returned.

    path        => 'lists/memberships',
    method      => 'GET',
    params      => [qw/user_id screen_name cursor filter_to_owned_lists/],
    required    => [],
    booleans    => [qw/filter_to_owned_lists/],
    returns     => 'Hashref',
);

twitter_api_method list_subscribers => (
    path        => 'lists/subscribers',
    method      => 'GET',
    params      => [qw/list_id slug owner_screen_name owner_id cursor include_entities skip_status/],
    required    => [],
    booleans    => [qw/include_entities skip_status/],
    returns     => 'Hashref',
    description => <<'',
Returns the subscribers of the specified list. Private list subscribers will
only be shown if the authenticated user owns the specified list.

);

twitter_api_method subscribe_list => (
    description => <<'',
Subscribes the authenticated user to the specified list.

    path        => 'lists/subscribers/create',
    method      => 'POST',
    params      => [qw/owner_screen_name owner_id list_id slug/],
    required    => [],
    returns     => 'List',
);

twitter_api_method show_list_subscriber => (
    description => <<'',
Returns the user if they are a subscriber.

    path        => 'lists/subscribers/show',
    aliases     => [qw/is_list_subscriber is_subscriber_lists/],
    method      => 'GET',
    params      => [qw/
        owner_screen_name owner_id list_id slug user_id screen_name
        include_entities skip_status
    /],
    required    => [],
    booleans    => [qw/include_entities skip_status/],
    returns     => 'User',
);

around [qw/is_list_subscriber is_subscriber_lists/] => sub {
    my $orig = shift;
    my $self = shift;

    $self->_user_or_undef($orig, 'subscriber', @_);
};

twitter_api_method unsubscribe_list => (
    description => <<'',
Unsubscribes the authenticated user from the specified list.

    path        => 'lists/subscribers/destroy',
    method      => 'POST',
    params      => [qw/list_id slug owner_screen_name owner_id/],
    required    => [],
    returns     => 'List',
);

twitter_api_method members_create_all => (
    description => <<'',
Adds multiple members to a list, by specifying a reference to an array or a
comma-separated list of member ids or screen names. The authenticated user must
own the list to be able to add members to it. Note that lists can't have more
than 500 members, and you are limited to adding up to 100 members to a list at
a time with this method.

    path        => 'lists/members/create_all',
    method      => 'POST',
    params      => [qw/list_id slug owner_screen_name owner_id/],
    required    => [],
    returns     => 'List',
    aliases     => [qw/add_list_members/],
);

twitter_api_method show_list_member => (
    description => <<'',
Check if the specified user is a member of the specified list. Returns the user or undef.

    path        => 'lists/members/show',
    aliases     => [qw/is_list_member/],
    method      => 'GET',
    params      => [qw/
        owner_screen_name owner_id list_id slug user_id screen_name
        include_entities skip_status
    /],
    required    => [],
    booleans    => [qw/include_entities skip_status/],
    returns     => 'Maybe[User]',
);

around is_list_member => sub {
    my $orig = shift;
    my $self = shift;

    $self->_user_or_undef($orig, 'member', @_);
};

twitter_api_method list_members => (
    description => <<'',
Returns the members of the specified list. Private list members will only be
shown if the authenticated user owns the specified list.

    path        => 'lists/members',
    method      => 'GET',
    params      => [qw/
        list_id slug owner_screen_name owner_id cursor
        include_entities skip_status
    /],
    required    => [],
    booleans    => [qw/include_entities skip_status/],
    returns     => 'Hashref',
);

twitter_api_method add_list_member => (
    description => <<'',
Add a member to a list. The authenticated user must own the list to be able to
add members to it. Note that lists can't have more than 500 members.

    path        => 'lists/members/create',
    method      => 'POST',
    params      => [qw/list_id slug user_id screen_name owner_screen_name owner_id/],
    required    => [],
    returns     => 'User',
);

twitter_api_method delete_list => (
    description => <<'',
Deletes the specified list. The authenticated user must own the list to be able
to destroy it.

    path        => 'lists/destroy',
    method      => 'POST',
    params      => [qw/owner_screen_name owner_id list_id slug/],
    required    => [],
    returns     => 'List',
);

twitter_api_method update_list => (
    description => <<'',
Updates the specified list. The authenticated user must own the list to be able
to update it.

    path        => 'lists/update',
    method      => 'POST',
    params      => [qw/list_id slug name mode description owner_screen_name owner_id/],
    required    => [],
    returns     => 'List',
);

twitter_api_method create_list => (
    description => <<'',
Creates a new list for the authenticated user. Note that you can't create more
than 20 lists per account.

    path        => 'lists/create',
    method      => 'POST',
    params      => [qw/list_id slug name mode description owner_screen_name owner_id/],
    required    => [qw/name/],
    returns     => 'List',
);

twitter_api_method get_list => (
    description => <<'',
Returns the specified list. Private lists will only be shown if the
authenticated user owns the specified list.

    aliases     => [qw/show_list/],
    path        => 'lists/show',
    method      => 'GET',
    params      => [qw/list_id slug owner_screen_name owner_id/],
    required    => [],
    returns     => 'List',
);

twitter_api_method list_subscriptions => (
    description => <<'',
Obtain a collection of the lists the specified user is subscribed to, 20 lists
per page by default. Does not include the user's own lists.

    path        => 'lists/subscriptions',
    method      => 'GET',
    params      => [qw/user_id screen_name count cursor/],
    required    => [],
    returns     => 'ArrayRef[List]',
    aliases     => [qw/subscriptions/],
);

twitter_api_method members_destroy_all => (
    description => <<'EOT',
Removes multiple members from a list, by specifying a reference to an array of
member ids or screen names, or a string of comma separated user ids or screen
names.  The authenticated user must own the list to be able to remove members
from it. Note that lists can't have more than 500 members, and you are limited
to removing up to 100 members to a list at a time with this method.

Please note that there can be issues with lists that rapidly remove and add
memberships. Take care when using these methods such that you are not too
rapidly switching between removals and adds on the same list.

EOT

    path        => 'lists/members/destroy_all',
    aliases     => [qw/remove_list_members/],
    method      => 'POST',
    params      => [qw/list_id slug user_id screen_name owner_screen_name owner_id/],
    required    => [],
    returns     => 'List',
);

twitter_api_method list_ownerships => (
    description => <<'',
Obtain a collection of the lists owned by the specified Twitter user. Private
lists will only be shown if the authenticated user is also the owner of the lists.

    path        => 'lists/ownerships',
    method      => 'GET',
    params      => [qw/user_id screen_name count cursor/],
    required    => [],
    returns     => 'ArrayRef[List]',
    aliases     => [],
);

## saved searches ##

twitter_api_method saved_searches => (
    description => <<'',
Returns the authenticated user's saved search queries.

    path     => 'saved_searches/list',
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

    aliases  => [qw/delete_saved_search/],
    path     => 'saved_searches/destroy/:id',
    method   => 'POST',
    params   => [qw/id/],
    required => [qw/id/],
    returns  => 'SavedSearch',
);

## geo ##

twitter_api_method geo_id => (
    description => <<'',
Returns details of a place returned from the C<reverse_geocode> method.

    path => 'geo/id/:id',
    method => 'GET',
    params => [qw/id/],
    required => [qw/id/],
    returns  => 'HashRef',
);

twitter_api_method reverse_geocode => (
    description => <<EOT,
Search for places (cities and neighborhoods) that can be attached to a
statuses/update.  Given a latitude and a longitude, return a list of all the
valid places that can be used as a place_id when updating a status.
Conceptually, a query can be made from the user's location, retrieve a list of
places, have the user validate the location he or she is at, and then send the
ID of this location up with a call to statuses/update.

There are multiple granularities of places that can be returned --
"neighborhoods", "cities", etc.  At this time, only United States data is
available through this method.

\=over 4

\=item lat

Required.  The latitude to query about.  Valid ranges are -90.0 to +90.0 (North
is positive) inclusive.

\=item long

Required. The longitude to query about.  Valid ranges are -180.0 to +180.0
(East is positive) inclusive.

\=item accuracy

Optional. A hint on the "region" in which to search.  If a number, then this is
a radius in meters, but it can also take a string that is suffixed with ft to
specify feet.  If this is not passed in, then it is assumed to be 0m.  If
coming from a device, in practice, this value is whatever accuracy the device
has measuring its location (whether it be coming from a GPS, WiFi
triangulation, etc.).

\=item granularity

Optional.  The minimal granularity of data to return.  If this is not passed
in, then C<neighborhood> is assumed.  C<city> can also be passed.

\=item max_results

Optional.  A hint as to the number of results to return.  This does not
guarantee that the number of results returned will equal max_results, but
instead informs how many "nearby" results to return.  Ideally, only pass in the
number of places you intend to display to the user here.

\=back

EOT

    path        => 'geo/reverse_geocode',
    method      => 'GET',
    params      => [qw/lat long accuracy granularity max_results callback/],
    required    => [qw/lat long/],
    returns     => 'HashRef',
);

twitter_api_method geo_search => (
    description => <<'EOT',
Search for places that can be attached to a statuses/update. Given a latitude
and a longitude pair, an IP address, or a name, this request will return a list
of all the valid places that can be used as the place_id when updating a
status.

Conceptually, a query can be made from the user's location, retrieve a list of
places, have the user validate the location he or she is at, and then send the
ID of this location with a call to statuses/update.

This is the recommended method to use find places that can be attached to
statuses/update. Unlike geo/reverse_geocode which provides raw data access,
this endpoint can potentially re-order places with regards to the user who
is authenticated. This approach is also preferred for interactive place
matching with the user.
EOT

    path        => 'geo/search',
    method      => 'GET',
    params      => [qw/
        lat long query ip granularity accuracy max_results
        contained_within attribute:street_address callback
    /],
    required    => [],
    returns     => 'HashRef',
);

twitter_api_method similar_places => (
    description => <<'EOT',
Locates places near the given coordinates which are similar in name.

Conceptually you would use this method to get a list of known places to choose
from first. Then, if the desired place doesn't exist, make a request to
C<add_place> to create a new one.

The token contained in the response is the token needed to be able to create a
new place.
EOT

    path        => 'geo/similar_places',
    method      => 'GET',
    params      => [qw/lat long name contained_within attribute:street_address callback/],
    required    => [qw/lat long name/],
    returns     => 'HashRef',
);

twitter_api_method add_place => (
    description => <<'EOT',
Creates a new place object at the given latitude and longitude.

Before creating a place you need to query C<similar_places> with the latitude,
longitude and name of the place you wish to create. The query will return an
array of places which are similar to the one you wish to create, and a token.
If the place you wish to create isn't in the returned array you can use the
token with this method to create a new one.
EOT

    path        => 'geo/place',
    method      => 'POST',
    params      => [qw/name contained_within token lat long attribute:street_address callback/],
    required    => [qw/name contained_within token lat long/],
    returns     => 'Place',
);

## trends ##

twitter_api_method trends_place => (
    description => <<'',
Returns the top 10 trending topics for a specific WOEID. The response is an
array of "trend" objects that encode the name of the trending topic, the query
parameter that can be used to search for the topic on Search, and the direct
URL that can be issued against Search.  This information is cached for five
minutes, and therefore users are discouraged from querying these endpoints
faster than once every five minutes.  Global trends information is also
available from this API by using a WOEID of 1.

    path        => 'trends/place',
    aliases     => [qw/trends_location/],
    method      => 'GET',
    params      => [qw/id exclude/],
    required    => [qw/id/],
    returns     => 'ArrayRef[Trend]',
);

# accept woeid parameter for backwards compatibility with old trends/location endpoint
around trends_location => sub {
    my $orig = shift;
    my $self = shift;

    carp "trends_location DEPRECATED: using trends_place({ id => ... }) instead";

    my $args = ref $_[-1] eq ref {} ? pop : {};
    $$args{id} = delete $$args{woeid} || shift;

    return $self->$orig($args);
};

twitter_api_method trends_available => (
    description => <<EOT,
Returns the locations with trending topic information. The response is an
array of "locations" that encode the location's WOEID (a Yahoo!  Where On Earth
ID L<http://developer.yahoo.com/geo/geoplanet/>) and some other human-readable
information such as a the location's canonical name and country.

For backwards compatibility, this method accepts optional C<lat> and C<long>
parameters. You should call C<trends_closest> directly, instead. 

Use the WOEID returned in the location object to query trends for a specific
location.
EOT

    path        => 'trends/available',
    method      => 'GET',
    params      => [],
    required    => [],
    returns     => 'ArrayRef[Location]',
);

around trends_available => sub {
    my $orig = shift;
    my $self = shift;

    my $args = ref $_[-1] eq ref {} ? pop : {};

    my $method = exists $$args{lat} || exists $$args{long} ? 'trends_closest' : $orig;

    return $self->$method(@_, $args);
};

twitter_api_method trends_closest => (
    description => <<EOT,
Returns the locations with trending topic information. The response is an array
of "locations" that encode the location's WOEID (a Yahoo!  Where On Earth ID
L<http://developer.yahoo.com/geo/geoplanet/>) and some other human-readable
information such as a the location's canonical name and country. The results
are sorted by distance from that location, nearest to farthest.

Use the WOEID returned in the location object to query trends for a specific
location.
EOT

    path        => 'trends/closest',
    method      => 'GET',
    params      => [qw/lat long/],
    required    => [],
    returns     => 'ArrayRef[Location]',
);

## spam reporting ##

twitter_api_method report_spam => (
    description => <<'',
The user specified in the id is blocked by the authenticated user and reported as a spammer.

    path     => 'users/report_spam',
    method   => 'POST',
    params   => [qw/user_id screen_name/],
    required => [qw/id/],
    returns  => 'User',
);

twitter_api_method get_languages => (
    description => <<'',
Returns the list of languages supported by Twitter along with their ISO 639-1
code. The ISO 639-1 code is the two letter value to use if you include lang
with any of your requests.

    path        => 'help/languages',
    method      => 'GET',
    params      => [],
    required    => [],
    returns     => 'ArrayRef[Lanugage]',
);

## Help ##

twitter_api_method get_configuration => (
    description => <<'EOT',
Returns the current configuration used by Twitter including twitter.com slugs
which are not usernames, maximum photo resolutions, and t.co URL lengths.

It is recommended applications request this endpoint when they are loaded, but
no more than once a day.
EOT

    path        => 'help/configuration',
    method      => 'GET',
    params      => [],
    required    => [],
    returns     => 'HashRef',
);

twitter_api_method get_privacy_policy => (
    description => <<'',
Returns Twitter's privacy policy.

    path        => 'help/privacy',
    method      => 'GET',
    params      => [],
    required    => [],
    returns     => 'HashRef',
);

twitter_api_method get_tos => (
    description => <<'',
Returns the Twitter Terms of Service. These are not the same as the Developer
Rules of the Road.

    path        => 'help/tos',
    method      => 'GET',
    params      => [],
    required    => [],
    returns     => 'HashRef',
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

    path     => 'application/rate_limit_status',
    method   => 'GET',
    params   => [qw/resources/],
    required => [qw//],
    returns  => 'RateLimitStatus',
);

# translate resources arrayref to a comma separated string 
around rate_limit_status => sub {
    my $orig = shift;
    my $self = shift;

    my $args = ref $_[-1] eq ref {} ? pop : {};
    croak "too many arguments" if @_;

    if ( exists $args->{resources} && ref $args->{resources} eq ref [] ) {
        $args->{resources} = join ',' => @{$args->{resources}};
    }

    return $self->$orig($args);
};

twitter_api_method test => (
    description => <<'',
Returns the string "ok" status code.

    path     => 'account/verify_credentials',
    method   => 'GET',
    params   => [qw//],
    required => [qw//],
    returns  => 'Hash',
    deprecated => sub { carp "$_[0] DEPRECATED: using verify_credentials instead" },
);

## not included in API v1.1 ##

twitter_api_method retweeted_by_me => (
    description => <<'',
Returns the 20 most recent retweets posted by the authenticating user.

    path      => 'statuses/retweeted_by_me',
    method    => 'GET',
    params    => [qw/since_id max_id count page trim_user include_entities/],
    booleans  => [qw/trim_user include_entities/],
    required  => [],
    returns   => 'ArrayRef[Status]',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

twitter_api_method retweeted_to_me => (
    description => <<'',
Returns the 20 most recent retweets posted by the authenticating user's friends.

    path      => 'statuses/retweeted_to_me',
    method    => 'GET',
    params    => [qw/since_id max_id count page/],
    required  => [],
    returns   => 'ArrayRef[Status]',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

twitter_api_method retweets_of_me => (
    description => <<'',
Returns the 20 most recent tweets of the authenticated user that have been
retweeted by others.

    aliases   => [qw/retweeted_of_me/],
    path      => 'statuses/retweets_of_me',
    method    => 'GET',
    params    => [qw/since_id max_id count trim_user include_entities include_user_entities/],
    booleans  => [qw/trim_user include_entities/],
    required  => [],
    returns   => 'ArrayRef[Status]',
);

twitter_api_method no_retweet_ids => (
    description => <<'',
Returns an ARRAY ref of user IDs for which the authenticating user does not
want to receive retweets.

    aliases  => [qw/no_retweets_ids/],
    path     => 'friendships/no_retweets/ids',
    method   => 'GET',
    params   => [],
    required => [],
    returns  => 'ArrayRef[UserIDs]',
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
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

twitter_api_method enable_notifications  => (
    description => <<'',
Enables notifications for updates from the specified user to the
authenticating user.  Returns the specified user when successful.

    path     => 'notifications/follow/:id',
    method   => 'POST',
    params   => [qw/id screen_name include_entities/],
    booleans => [qw/include_entities/],
    required => [qw/id/],
    returns  => 'BasicUser',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

around enable_notifications => sub {
    my $orig = shift;
    my $self = shift;

    return $self->_enable_disable_notifications(1, @_);
};

sub _enable_disable_notifications {
    my $self = shift;
    my $enable = shift;

    carp "enable_notifications/disable_notifications DEPRECATED: using update_friendship instead";

    my $args = ref $_[-1] eq ref {} ? pop : {};
    $$args{device} = $enable;
    return $self->update_friendship(@_, $args);
};

twitter_api_method disable_notifications => (
    description => <<'',
Disables notifications for updates from the specified user to the
authenticating user.  Returns the specified user when successful.

    path     => 'notifications/leave/:id',
    method   => 'POST',
    params   => [qw/id screen_name include_entities/],
    booleans => [qw/include_entities/],
    required => [qw/id/],
    returns  => 'BasicUser',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

around disable_notifications => sub {
    my $orig = shift;
    my $self = shift;

    return $self->_enable_disable_notifications(0, @_);
};

twitter_api_method block_exists => (
    description => <<'',
Returns if the authenticating user is blocking a target user. Will return the blocked user's
object if a block exists, and error with HTTP 404 response code otherwise.

    path     => 'blocks/exists/:id',
    method   => 'GET',
    params   => [qw/id user_id screen_name include_entities/],
    booleans => [qw/include_entities/],
    required => [qw/id/],
    returns  => 'BasicUser',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

twitter_api_method trends_current => (
    description => <<'',
Returns the current top ten trending topics on Twitter.  The response includes
the time of the request, the name of each trending topic, and query used on
Twitter Search results page for that topic.

    path     => 'trends/current',
    method   => 'GET',
    params   => [qw/exclude/],
    required => [qw//],
    returns  => 'HashRef',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

around trends_current => sub {
    my $orig = shift;
    my $self = shift;

    carp "trends_current DEPRECATED: using trends_place({ id => 1 }) instead";

    my $args = ref $_[-1] eq ref {} ? pop : {};
    $$args{id} = 1;

    return $self->trends_place($args);
};

twitter_api_method trends_daily => (
    description => <<'',
Returns the top 20 trending topics for each hour in a given day.

    path     => 'trends/daily',
    method   => 'GET',
    params   => [qw/date exclude/],
    required => [qw//],
    returns  => 'HashRef',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

twitter_api_method trends_weekly => (
    description => <<'',
Returns the top 30 trending topics for each day in a given week.

    path     => 'trends/weekly',
    method   => 'GET',
    params   => [qw/date exclude/],
    required => [qw//],
    returns  => 'HashRef',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

twitter_api_method retweeted_by => (
    description => <<'',
Returns up to 100 users who retweeted the status identified by C<id>.

    path => 'statuses/:id/retweeted_by',
    method => 'GET',
    params => [qw/id count page trim_user include_entities/],
    booleans => [qw/include_entities trim_user/],
    required => [qw/id/],
    returns  => 'ArrayRef[User]',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

twitter_api_method retweeted_by_ids => (
    description => <<'',
Returns the IDs of up to 100 users who retweeted the status identified by C<id>.

    path     => 'statuses/:id/retweeted_by/ids',
    method   => 'GET',
    params   => [qw/id count page trim_user include_entities/],
    booleans => [qw/include_entities trim_user/],
    required => [qw/id/],
    returns  => 'ArrayRef[User]',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

# new in 3.17001 2010-10-19

twitter_api_method account_totals => (
    description => <<'',
Returns the current count of friends, followers, updates (statuses)
and favorites of the authenticating user.

    path        => 'account/totals',
    method      => 'GET',
    params      => [],
    required    => [],
    returns     => 'HashRef',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

twitter_api_method retweeted_to_user => (
    description => <<'',
Returns the 20 most recent retweets posted by users the specified user
follows. The user is specified using the user_id or screen_name
parameters. This method is identical to C<retweeted_to_me>
except you can choose the user to view.
Does not require authentication, unless the user is protected.

    path => 'statuses/retweeted_to_user',
    method      => 'GET',
    params      => [qw/id user_id screen_name/],
    required    => [qw/id/],
    returns     => 'ArrayRef',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

twitter_api_method retweeted_by_user => (
    description => <<'',
Returns the 20 most recent retweets posted by the specified user. The user is
specified using the user_id or screen_name parameters. This method is identical
to C<retweeted_by_me> except you can choose the user to view.  Does not require
authentication, unless the user is protected.

    path        => 'statuses/retweeted_by_user',
    method      => 'GET',
    params      => [qw/id user_id screen_name/],
    required    => [qw/id/],
    returns     => 'ArrayRef',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

twitter_api_method related_results => (
    description => <<'',
If available, returns an array of replies and mentions related to the specified
status. There is no guarantee there will be any replies or mentions in the
response. This method is only available to users who have access to
#newtwitter.  Requires authentication.

    path        => 'related_results/show/:id',
    method      => 'GET',
    params      => [qw/id/],
    required    => [qw/id/],
    returns     => 'ArrayRef[Status]',
    deprecated => sub { croak "$_[0] not available in Twitter API V1.1" },
);

twitter_api_method remove_profile_banner => (
    description => <<'',
Removes the uploaded profile banner for the authenticating user.

    path     => 'account/remove_profile_banner',
    method   => 'POST',
    params   => [qw//],
    required => [qw//],
    returns  => 'Nothing',
);

twitter_api_method update_profile_banner => (
    description => <<'EOT',
Uploads a profile banner on behalf of the authenticating user.  The C<image>
parameter is an arrayref with the following interpretation:

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

    path     => 'account/update_profile_banner',
    method   => 'POST',
    params   => [qw/banner width height offset_left offset_top/],
    required => [qw/banner/],
    returns  => 'Nothing',
);

twitter_api_method profile_banner => (
    description => <<'',
Returns a hash reference mapping available size variations to URLs that can be
used to retrieve each variation of the banner.

    path     => 'users/profile_banner',
    method   => 'GET',
    params   => [qw/user_id screen_name/],
    required => [qw//],
    returns  => 'HashRef',
);

twitter_api_method muting_ids => (
    description => <<'',
Returns an array of numeric user ids the authenticating user has muted.

    path     => 'mutes/users/ids',
    aliases  => [qw//],
    method   => 'GET',
    params   => [qw/cursor/],
    required => [qw//],
    booleans => [qw//],
    returns  => 'ArrayRef[Int]',
);

# infer screen_name or user_id from positional args for backwards compatibility
# and convenience
around [qw/
    show_user
    create_friend
    follow_new
    destroy_friend
    unfollow
    friends_ids
    following_ids
    followers_ids
    create_block
    destroy_block
    block_exists
    report_spam
    retweeted_by_user
    update_friendship
/] => sub {
    my $orig = shift;
    my $self = shift;

    my $args = ref $_[-1] eq ref {} ? pop : {};
    if ( @_ && !exists $$args{user_id} && !exists $$args{screen_name} ) {
        my $id = shift;
        $$args{$id =~ /^\d+\$/ ? 'user_id' : 'screen_name' } = $id;
    }

    return $self->$orig(@_, $args);
};

1;

__END__


=head1 NAME

Net::Twitter::Role::API::RESTv1_1 - A definition of the Twitter REST API v1.1 as a Moose role

=head1 SYNOPSIS

  package My::Twitter;
  use Moose;
  with 'Net::Twitter::API::RESTv1_1';

=head1 DESCRIPTION

B<Net::Twitter::Role::API::RESTv1_1> provides definitions for all the Twitter REST API
v1.1 methods.  Applying this role to any class provides methods for all of the
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
