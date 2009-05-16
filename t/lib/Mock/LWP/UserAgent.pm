package # hide from PAUSE
    Mock::LWP::UserAgent;

# Origninally written as TestUA for Net::Twitter by Marc Mims
# modified for Net::Twitter::Lite

$INC{'LWP/UserAgent.pm'} = __FILE__;

package # hide from PAUSE
    LWP::UserAgent;

use HTTP::Response;
use warnings;
use strict;
use URI;

### Extracted from Net/Twitter.pm

my %twitter_api = (
    "/statuses/public_timeline" => {
        "blankargs" => 1,
        "post"      => 0,
        "args"      => {},
    },
    "/statuses/friends_timeline" => {
        "blankargs" => 1,
        "post"      => 0,
        "args"      => {
            "since"    => 0,
            "since_id" => 0,
            "count"    => 0,
            "page"     => 0,
        },
    },
    "/statuses/user_timeline" => {
        "has_id"    => 1,
        "blankargs" => 1,
        "post"      => 0,
        "args"      => {
            "id"       => 0,
            "since"    => 0,
            "since_id" => 0,
            "count"    => 0,
            "page"     => 0,
        },
    },
    "/statuses/show" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 0,
        "args"      => { "id" => 1, },
    },
    "/statuses/update" => {
        "blankargs" => 0,
        "post"      => 1,
        "args"      => {
            "status"                => 1,
            "in_reply_to_status_id" => 0,
            "source"                => 0,
        },
    },
    "/statuses/mentions" => {
        "blankargs" => 1,
        "post"      => 0,
        "args"      => {
            "page"     => 0,
            "since"    => 0,
            "since_id" => 0,
        },
    },
    "/statuses/destroy" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 1,
        "args"      => { "id" => 1, },
    },
    "/statuses/friends" => {
        "has_id"    => 1,
        "blankargs" => 1,
        "post"      => 0,
        "args"      => {
            "id"    => 0,
            "page"  => 0,
            "since" => 0,
        },
    },
    "/statuses/followers" => {
        "blankargs" => 1,
        "post"      => 0,
        "args"      => {
            "id"   => 0,
            "page" => 0,
        },
    },
    "/users/show" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 0,
        "args"      => {
            "id"    => 1,
            "email" => 1,
        },
        required => sub {
            my $args = shift;
            # one, but not both
            return (exists $args->{id} xor exists $args->{email});
        },
    },
    "/direct_messages" => {
        "blankargs" => 1,
        "post"      => 0,
        "args"      => {
            "since"    => 0,
            "since_id" => 0,
            "page"     => 0,
        },
    },
    "/direct_messages/sent" => {
        "blankargs" => 1,
        "post"      => 0,
        "args"      => {
            "since"    => 0,
            "since_id" => 0,
            "page"     => 0,
        },
    },
    "/direct_messages/new" => {
        "blankargs" => 0,
        "post"      => 1,
        "args"      => {
            "user" => 1,
            "text" => 1,
        },
    },
    "/direct_messages/destroy" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 1,
        "args"      => { "id" => 1, },
    },
    "/friends/ids" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 0,
        "args"      => { "id" => 0, },
    },
    "/followers/ids" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 0,
        "args"      => { "id" => 0, },
    },
    "/friendships/create" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 1,
        "args"      => {
            "id"     => 1,
            "follow" => 0,
        },
    },
    "/friendships/destroy" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 1,
        "args"      => { "id" => 1, },
    },
    "/friendships/exists" => {
        "blankargs" => 0,
        "post"      => 0,
        "args"      => {
            "user_a" => 1,
            "user_b" => 1,
        },
    },
    "/account/verify_credentials" => {
        "blankargs" => 1,
        "post"      => 0,
        "args"      => {},
    },
    "/account/end_session" => {
        "blankargs" => 1,
        "post"      => 1,
        "args"      => {},
    },
    "/account/update_profile_colors" => {
        "blankargs" => 0,
        "post"      => 1,
        "args"      => {
            "profile_background_color"     => 0,
            "profile_text_color"           => 0,
            "profile_link_color"           => 0,
            "profile_sidebar_fill_color"   => 0,
            "profile_sidebar_border_color" => 0,
        },
    },
    "/account/update_profile_image" => {
        "blankargs" => 0,
        "post"      => 1,
        "args"      => { "image" => 1, },
    },
    "/account/update_location" => {
        "blankargs" => 0,
        "post"      => 1,
        "args"      => { "location" => 1, },
    },
    "/account/update_profile_background_image" => {
        "blankargs" => 0,
        "post"      => 1,
        "args"      => { "image" => 1, },
    },
    "/account/update_profile" => {
        "blankargs" => 0,
        "post"      => 1,
        "args"      => {
            name    => 0,
            email   => 0,
            url     => 0,
            location => 0,
            description => 0,
        },
    },
    "/account/update_delivery_device" => {
        "blankargs" => 0,
        "post"      => 1,
        "args"      => { "device" => 1, },
    },
    "/account/rate_limit_status" => {
        "blankargs" => 1,
        "post"      => 0,
        "args"      => {},
    },
    "/favorites" => {
        "blankargs" => 1,
        "post"      => 0,
        "args"      => {
            "id"   => 0,
            "page" => 0,
        },
    },
    "/favorites/create" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 1,
        "args"      => { "id" => 1, },
    },
    "/favorites/destroy" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 1,
        "args"      => { "id" => 1, },
    },
    "/notifications/follow" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 1,
        "args"      => { "id" => 1, },
    },
    "/notifications/leave" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 1,
        "args"      => { "id" => 1, },
    },
    "/blocks/create" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 1,
        "args"      => { "id" => 1, },
    },
    "/blocks/destroy" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 1,
        "args"      => { "id" => 1, },
    },
    "/blocks/exists" => {
        "has_id"    => 1,
        "blankargs" => 0,
        "post"      => 0,
        "args"      => { "id" => 1, },
    },
    "/blocks/blocking" => {
        "has_id"    => 0,
        "blankargs" => 0,
        "post"      => 0,
        "args"      => {},
    },
    "/blocks/ids" => {
        "has_id"    => 0,
        "blankargs" => 1,
        "post"      => 0,
        "args"      => {},
    },
    "/help/test" => {
        "blankargs" => 1,
        "post"      => 0,
        "args"      => {},
    },
    "/help/downtime_schedule" => {
        "blankargs" => 100,
        "post"      => 0,
        "args"      => {},
    },
    '/search' => {
        blankargs => 0,
        post      => 0,
        args      => {
            q   => 1,
            lang => 0,
            rpp  => 0,
            page    => 0,
            since_id    => 0,
            geocode     => 0,
            show_user   => 0,
        },
    },
    '/trends' => {
        blankargs   => 1,
        post        => 0,
        args        => {},
    },

);

sub new {
    my $class = shift;
    return bless {
        _host => 'twitter.com',
    }, $class;
}

sub credentials {}

sub agent {}

sub default_header {}

sub env_proxy {}

sub get {
    my ($self, $url) = @_;

    my $uri = URI->new($url);
    $self->{_input_uri} = $uri->clone; # stash for tests
    $self->{_input_method} = 'GET';
    eval { $self->_validate_basic_url($uri) };
    chomp $@, return $self->_error_response(400, $@) if $@;

    # strip the args
    my %args = $uri->query_form;
    $uri->query_form([]);

    return $self->_twitter_rest_api('GET', $uri, \%args);
}

sub post {
    my ($self, $url, $args) = @_;

    my $uri = URI->new($url);
    $self->{_input_uri} = $uri->clone; # stash for tests
    $self->{_input_method} = 'POST';
    eval { $self->_validate_basic_url($uri) };
    chomp $@, return $self->_error_response(400, $@) if $@;

    return $self->_error_response(400, "POST $url contains parameters") if $uri->query_form;
    return $self->_twitter_rest_api('POST', $uri, $args);
}

sub _twitter_rest_api {
    my ($self, $method, $uri, $args) = @_;

    my ($path, $id) = eval { $self->_parse_path_id($uri) };

    chomp $@, return $self->_error_response(400, $@) if $@;

    return $self->_error_response(400, "Bad URL, /ID.json present.") if $uri =~ m/ID.json/;

    my $api_entry = $twitter_api{$path}
        || return $self->error_response(404, "$path is not a twitter api entry");

    # TODO: What if ID is passed in the URL and args? What if the 2 are different?
    $args->{id} = $id if $api_entry->{has_id} && defined $id && $id;

    $self->{_input_args} = { %$args }; # save a copy of input args for tests

    return $self->_error_response(400, "expected POST")
        if  $api_entry->{post} && $method ne 'POST';
    return $self->_error_response(400, "expected GET")
        if !$api_entry->{post} && $method ne 'GET';

    if ( my $coderef = $api_entry->{required} ) {
        unless ( $coderef->($args) ) {
            return $self->_error_response(400, "requried args test failed");
        }
    }
    else {
        my @required = grep { $api_entry->{args}{$_} } keys %{$api_entry->{args}};
        if ( my @missing = grep { !exists $args->{$_} } @required ) {
            return $self->_error_response(400, "$path -> requried args missing: @missing");
        }
    }

    if ( my @undefined = grep { $args->{$_} eq '' } keys %$args ) {
        return $self->_error_response(400, "args with undefined values: @undefined");
    }

    my %unexpected_args = map { $_ => 1 } keys %$args;
    delete $unexpected_args{$_} for keys %{$api_entry->{args}};
    if ( my @unexpected_args = sort keys %unexpected_args ) {
        # twitter seems to ignore unexpected args, so don't fail, just diag
        print "# unexpected args: @unexpected_args\n" if $self->print_diags;
    }

    return $self->_response;
}

sub _validate_basic_url {
    my ($self, $url) = @_;

    my $uri = URI->new($url);

    die "scheme: expected http\n" unless $uri->scheme eq 'http';
    die "bad host\n" unless $uri->host eq $self->_host;
    die "expected .json\n" unless (my $path = $uri->path) =~ s/\.json$//;

    $uri->path($path);
}

sub _error_response {
    my ($self, $rc, $msg) = @_;

    print "# $msg\n" if $self->print_diags;
    return $self->_response(_rc => $rc, _msg => $msg, _content => $msg);
}

sub _response {
    my ($self, %args) = @_;

    bless {
        _content => $self->{_res_content} || '{"test":"1"}',
        _rc      => $self->{_res_code   } || 200,
        _msg     => $self->{_res_message} || 'OK',
        _headers => {},
        %args,
    }, 'HTTP::Response';
}

sub _parse_path_id {
    my ($self, $uri) = @_;

    (my $path = $uri->path) =~ s/\.json$//;
    return ($path) if $twitter_api{$path};

    my ($ppath, $id) = $path =~ /(.*)\/(.*)$/;

    return ($ppath, $id) if $twitter_api{$ppath} && $twitter_api{$ppath}{has_id};

    die "$path is not a twitter_api method\n";
}

sub print_diags {
    my $self = shift;

    return $self->{_print_diags} unless @_;
    $self->{_print_diags} = shift;
}

sub input_args {
    my $self = shift;

    return $self->{_input_args} || {};
}

sub input_uri { shift->{_input_uri} }

sub input_method { shift->{_input_method} }

sub set_response {
    my ($self, $args) = @_;

    @{$self}{qw/_res_code _res_message _res_content/} = @{$args}{qw/code message content/};
    ref $args->{content}
        && ( $self->{_res_content} = eval { JSON::Any->to_json($args->{content}) } )
        || ref $args->{content};
}

sub clear_response { delete @{shift()}{qw/_res_code _res_message _re_content/} }

sub _host {
    my $self = shift;

    $self->{_host} = shift if @_;
    return $self->{_host};
}

1;
