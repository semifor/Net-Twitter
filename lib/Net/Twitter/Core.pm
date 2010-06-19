package Net::Twitter::Core;
use 5.008001;
use Moose;
use MooseX::MultiInitArg;
use Carp;
use JSON::Any qw/XS JSON/;
use URI::Escape;
use HTTP::Request::Common;
use Net::Twitter::Error;
use Scalar::Util qw/blessed reftype/;
use List::Util qw/first/;
use HTML::Entities;
use Encode qw/encode_utf8/;
use DateTime;
use Data::Visitor::Callback;

use namespace::autoclean;

# use *all* digits for fBSD ports
our $VERSION = '3.13004';

$VERSION = eval $VERSION; # numify for warning-free dev releases

has useragent_class => ( isa => 'Str', is => 'ro', default => 'LWP::UserAgent' );
has useragent_args  => ( isa => 'HashRef', is => 'ro', default => sub { {} } );
has username        => ( traits => [qw/MooseX::MultiInitArg::Trait/],
                         isa => 'Str', is => 'rw', predicate => 'has_username',
                         init_args => [qw/user/] );
has password        => ( traits => [qw/MooseX::MultiInitArg::Trait/],
                         isa => 'Str', is => 'rw', predicate => 'has_password',
                         init_args => [qw/pass/] );
has ssl             => ( isa => 'Bool', is => 'ro', default => 0 );
has netrc           => ( isa => 'Str', is => 'ro', predicate => 'has_netrc' );
has netrc_machine   => ( isa => 'Str', is => 'ro', default => 'api.twitter.com' );
has decode_html_entities => ( isa => 'Bool', is => 'rw', default => 0 );
has useragent       => ( isa => 'Str', is => 'ro', default => "Net::Twitter/$VERSION (Perl)" );
has source          => ( isa => 'Str', is => 'ro', default => 'twitterpm' );
has ua              => ( isa => 'Object', is => 'rw', lazy => 1, builder => '_build_ua' );
has clientname      => ( isa => 'Str', is => 'ro', default => 'Perl Net::Twitter' );
has clientver       => ( isa => 'Str', is => 'ro', default => $VERSION );
has clienturl       => ( isa => 'Str', is => 'ro', default => 'http://search.cpan.org/dist/Net-Twitter/' );
has _base_url       => ( is => 'rw' ); ### keeps role composition from bitching ??
has _json_handler   => (
    is      => 'rw',
    default => sub { JSON::Any->new(utf8 => 1) },
    handles => { _from_json => 'from_json' },
);

sub _synthetic_args { qw/authenticate since/ }

sub _extract_synthetic_args {
    my ( $self, $args ) = @_;

    my $synthetic_args = {};
    for my $k ( $self->_synthetic_args ) {
        $synthetic_args->{$k} = delete $args->{$k} if exists $args->{$k};
    }

    return $synthetic_args;
}

sub BUILD {
    my $self = shift;

    if ( $self->has_netrc ) {
        require Net::Netrc;

        # accepts '1' for backwards compatibility
        my $host = $self->netrc eq '1' ? $self->netrc_machine : $self->netrc;
        my $nrc  = Net::Netrc->lookup($host)
            || croak "No .netrc entry for $host";

        my ($user, $pass) = $nrc->lpa;
        $self->username($user);
        $self->password($pass);
    }

    $self->credentials($self->username, $self->password) if $self->has_username;
}

sub _build_ua {
    my $self = shift;

    eval "use " . $self->useragent_class;
    croak $@ if $@;

    my $ua = $self->useragent_class->new(%{$self->useragent_args});
    $ua->agent($self->useragent);
    $ua->default_header('X-Twitter-Client'         => $self->clientname);
    $ua->default_header('X-Twitter-Client-Version' => $self->clientver);
    $ua->default_header('X-Twitter-Client-URL'     => $self->clienturl);
    $ua->env_proxy;

    return $ua;
}

sub credentials {
    my ($self, $username, $password) = @_;

    $self->username($username);
    $self->password($password);

    return $self; # make it chainable
}

sub _encode_args {
    my ($self, $args) = @_;

    # Values need to be utf-8 encoded.  Because of a perl bug, exposed when
    # client code does "use utf8", keys must also be encoded.
    # see: http://www.perlmonks.org/?node_id=668987
    # and: http://perl5.git.perl.org/perl.git/commit/eaf7a4d2
    return { map { utf8::upgrade($_) unless ref($_); $_ } %$args };
}

sub _json_request { 
    my ($self, $http_method, $uri, $args, $authenticate, $synthetic_args, $dt_parser) = @_;
    
    return $self->_parse_result(
        $self->_prepare_request($http_method, $uri, $args, $authenticate),
        $synthetic_args,
        $dt_parser,
    );
}

sub _prepare_request {
    my ($self, $http_method, $uri, $args, $authenticate) = @_;

    my $msg;

    $self->_encode_args($args);

    if ( $http_method =~ /^(?:GET|DELETE)$/ ) {
        $uri->query_form($args);
        $msg = HTTP::Request->new($http_method, $uri);
    }
    elsif ( $http_method eq 'POST' ) {
        # if any of the arguments are (array) refs, use form-data
        $msg = (first { ref } values %$args)
             ? POST($uri,
                    Content_Type => 'form-data',
                    Content      => [ %$args ],
               )
             : POST($uri, $args)
             ;
    }
    else {
        croak "unexpected HTTP method: $http_method";
    }

    $self->_add_authorization_header($msg, $args) if $authenticate;

    return $self->_send_request($msg);
}

# Basic Auth, overridden by Role::OAuth, if included
sub _add_authorization_header {
    my ( $self, $msg ) = @_;

    $msg->headers->authorization_basic($self->username, $self->password)
        if $self->has_username && $self->has_password;
}

sub _send_request { shift->ua->request(shift) }

# Twitter returns HTML encoded entities in the "text" field of status messages.
# Decode them.
sub _decode_html_entities {
    my ($self, $obj) = @_;

    if ( ref $obj eq 'ARRAY' ) {
        $self->_decode_html_entities($_) for @$obj;
    }
    elsif ( ref $obj eq 'HASH' ) {
        $self->_decode_html_entities($_) for values %$obj;
        decode_entities($obj->{text}) if exists $obj->{text};
    }
}

# By default, Net::Twitter does not inflate objects, so just return the
# hashref, untouched. This is really just a hook for Role::InflateObjects.
sub _inflate_objects { return $_[2] }

sub _parse_result {
    my ($self, $res, $synthetic_args, $datetime_parser) = @_;

    # workaround for Laconica API returning bools as strings
    # (Fixed in Laconi.ca 0.7.4)
    my $content = $res->content;
    $content =~ s/^"(true|false)"$/$1/;

    my $obj = eval { $self->_from_json($content) };
    $self->_decode_html_entities($obj) if $obj && $self->decode_html_entities;

    # inflate the twitter object(s) if possible
    $self->_inflate_objects($datetime_parser, $obj);

    # Twitter sometimes returns an error with status code 200
    if ( ref $obj && reftype $obj eq 'HASH' && exists $obj->{error} ) {
        die Net::Twitter::Error->new(twitter_error => $obj, http_response => $res);
    }

    if  ( $res->is_success && defined $obj ) {
        if ( my $since = delete $synthetic_args->{since} ) {
            $self->_filter_since($datetime_parser, $obj, $since);
        }
        return $obj;
    }

    my $error = Net::Twitter::Error->new(http_response => $res);
    $error->twitter_error($obj) if ref $obj;

    die $error;
}

# Return a DateTime object, given $since as one of:
#   - DateTime object
#   - string in format "YYYY-MM-DD"
#   - string in the same format as created_at values for the particular
#     Twitter API (Search and REST have different created_at formats!)
#   - an integer with epoch time (in seconds)
# Otherwise, throw an exception
sub _since_as_datetime {
    my ($self, $since, $parser) = @_;

    return $since if blessed($since) && $since->isa('DateTime');

    if ( my ($y, $m, $d) = $since =~ /^(\d{4})-(\d{2})-(\d{2})$/ ) {
        return DateTime->new(month => $m, day => $d, year => $y);
    }

    return eval { DateTime->from_epoch(epoch => $since) }
        || eval { $parser->parse_datetime($since) }
        || croak
"Invalid 'since' parameter: $since. Must be a DateTime, epoch, string in Twitter timestamp format, or YYYY-MM-DD.";
}

sub _filter_since {
    my ($self, $datetime_parser, $obj, $since) = @_;

    # $since can be a DateTime, an epoch value, or a Twitter formatted timestamp
    my $since_dt  = $self->_since_as_datetime($since, $datetime_parser);

    my $visitor = Data::Visitor::Callback->new(
        ignore_return_values => 1,
        array => sub {
            my ($visitor, $data) = @_;

            return unless $self->_contains_statuses($data);

            # truncate $data when we reach an item as old or older than $since_dt
            my $i = 0;
            while ( $i < @$data ) {
                last if $datetime_parser->parse_datetime($data->[$i]{created_at}) <= $since_dt;
                ++$i;
            }
            $#{$data} = $i;
        }
    );

    $visitor->visit($obj);
}

# check an arrayref to see if it contains satuses
sub _contains_statuses {
    my ($self, $arrayref) = @_;

    my $e = $arrayref->[0] || return;
    return unless ref $e && reftype $e eq 'HASH';
    return exists $e->{created_at} && exists $e->{text} && exists $e->{id};
}

1;

__END__

=head1 NAME

Net::Twitter::Core - Net::Twitter implementation

=head1 SYNOPSIS

  use Net::Twitter::Core;

  my $nt = Net::Twitter::Core->new_with_traits(traits => [qw/API::Search/]);

  my $tweets = $nt->search('perl twitter')

=head1 DESCRIPTION

This module implements the core features of C<Net::Twitter>.  See L<Net::Twitter> for full documentation.

Although this module can be used directly, you are encouraged to use C<Net::Twitter> instead.

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
