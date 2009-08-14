package Net::Twitter::Core;
use 5.008001;
use Moose;
use MooseX::MultiInitArg;
use Carp;
use JSON::Any qw/XS JSON/;
use URI::Escape;
use HTTP::Request::Common;
use Net::Twitter::Error;
use Scalar::Util qw/reftype/;
use HTML::Entities;
use Encode;

use namespace::autoclean;

# use *all* digits for fBSD ports
our $VERSION = '3.04006';

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
has netrc           => ( isa => 'Bool', is => 'ro', default => 0 );
has decode_html_entities => ( isa => 'Bool', is => 'rw', default => 0 );
has useragent       => ( isa => 'Str', is => 'ro', default => "Net::Twitter/$VERSION (Perl)" );
has source          => ( isa => 'Str', is => 'ro', default => 'twitterpm' );
has ua              => ( isa => 'Object', is => 'rw' );
has clientname      => ( isa => 'Str', is => 'ro', default => 'Perl Net::Twitter' );
has clientver       => ( isa => 'Str', is => 'ro', default => $VERSION );
has clienturl       => ( isa => 'Str', is => 'ro', default => 'http://search.cpan.org/dist/Net-Twitter/' );
has _base_url       => ( is => 'rw' ); ### keeps role composition from bitching ??
has _json_handler   => (
    is      => 'rw',
    default => sub { JSON::Any->new(utf8 => 1) },
    handles => { _from_json => 'from_json' },
);

sub BUILD {
    my $self = shift;

    eval "use " . $self->useragent_class;
    croak $@ if $@;

    $self->{apiurl} =~ s/http/https/ if $self->ssl;

    if ( $self->netrc ) {
        require Net::Netrc;

        my $host = URI->new($self->apiurl)->host;
        my $nrc  = Net::Netrc->lookup($host)
            || croak "No .netrc entry for $host";

        my ($user, $pass) = $nrc->lpa;
        $self->username($user);
        $self->password($pass);
    }

    $self->ua($self->useragent_class->new(%{$self->useragent_args}));
    $self->ua->agent($self->useragent);
    $self->ua->default_header('X-Twitter-Client'         => $self->clientname);
    $self->ua->default_header('X-Twitter-Client-Version' => $self->clientver);
    $self->ua->default_header('X-Twitter-Client-URL'     => $self->clienturl);
    $self->ua->env_proxy;
    $self->credentials($self->username, $self->password) if $self->has_username;
}

sub credentials {
    my ($self, $username, $password) = @_;

    $self->username($username);
    $self->password($password);

    return $self; # make it chainable
}

# Basic Auth, overridden by Role::OAuth, if included
sub _authenticated_request {
    my ($self, $http_method, $uri, $args, $authenticate) = @_;

    my $msg;

    $_ = encode('utf-8', $_) for values %$args;

    if ( $http_method eq 'GET' ) {
        $uri->query_form($args);
        $msg = GET($uri);
    }
    elsif ( $http_method eq 'POST' ) {
        $msg = POST($uri, $args);
    }
    else {
        croak "unexpected HTTP method: $http_method";
    }

    $msg->headers->authorization_basic($self->username, $self->password)
        if $authenticate && $self->has_username && $self->has_password;

    return $self->ua->request($msg);
}

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
sub _inflate_objects { return $_[1] }

sub _parse_result {
    my ($self, $res) = @_;

    # workaround for Laconica API returning bools as strings
    # (Fixed in Laconi.ca 0.7.4)
    my $content = $res->content;
    $content =~ s/^"(true|false)"$/$1/;

    my $obj = eval { $self->_from_json($content) };
    $self->_decode_html_entities($obj) if $obj && $self->decode_html_entities;

    # inflate the twitter object(s) if possible
    $self->_inflate_objects($obj);

    # Twitter sometimes returns an error with status code 200
    if ( ref $obj && reftype $obj eq 'HASH' && exists $obj->{error} ) {
        die Net::Twitter::Error->new(twitter_error => $obj, http_response => $res);
    }

    return $obj if $res->is_success && defined $obj;

    my $error = Net::Twitter::Error->new(http_response => $res);
    $error->twitter_error($obj) if ref $obj;

    die $error;
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
