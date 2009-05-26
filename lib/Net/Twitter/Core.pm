package Net::Twitter::Core;
use 5.8.1;
use Moose;
use Carp;
use JSON::Any qw/XS DWIW JSON/;
use URI::Escape;
use Net::Twitter::Error;

use namespace::autoclean;

with 'MooseX::Traits';

# use *all* digits for fBSD ports
our $VERSION = '2.99000_05';

$VERSION = eval $VERSION; # numify for warning-free dev releases

# For transparent legacy support, we need ->isa('Net::Twitter') to succeed.
# TODO: MOP is not picking up UNIVERSAL methods. When it does, this code needs
# to be removed and the around isa => sub {...} uncommented in Legacy.
sub isa {
    my ($class, $isa) = @_;

    return 1 if $isa && !ref $isa && $isa eq 'Net::Twitter';

    return $class->SUPER::isa($isa);
}

has useragent_class => ( isa => 'Str', is => 'ro', default => 'LWP::UserAgent' );
has useragent_args  => ( isa => 'HashRef', is => 'ro', default => sub { {} } );
has username        => ( isa => 'Str', is => 'rw', predicate => 'has_username' );
has password        => ( isa => 'Str', is => 'rw' );
has useragent       => ( isa => 'Str', is => 'ro', default => "Net::Twitter/$VERSION (Perl)" );
has source          => ( isa => 'Str', is => 'ro', default => 'twitterpm' );
has ua              => ( isa => 'Object', is => 'rw' );
has clientname      => ( isa => 'Str', is => 'ro', default => 'Perl Net::Twitter' );
has clientver       => ( isa => 'Str', is => 'ro', default => $VERSION );
has clienturl       => ( isa => 'Str', is => 'ro', default => 'http://search.cpan.org/dist/Net-Twitter/' );
has '+_trait_namespace' => ( default => 'Net::Twitter' );
has _base_url       => ( is => 'rw' ); ### keeps role composition from bitching ??

sub BUILD {
    my $self = shift;

    eval "use " . $self->useragent_class;
    croak $@ if $@;

    $self->ua($self->useragent_class->new($self->useragent_args));
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

sub _from_json {
    my ($self, $json) = @_;

    return eval { JSON::Any->from_json($json) };
}

sub _parse_result {
    my ($self, $res) = @_;

    my $obj = $self->_from_json($res->content);

    # Twitter sometimes returns an error with status code 200
    if ( $obj && ref $obj eq 'HASH' && exists $obj->{error} ) {
        die Net::Twitter::Error->new(twitter_error => $obj, http_response => $res);
    }

    return $obj if $res->is_success && $obj;

    my $error = Net::Twitter::Error->new(http_response => $res);
    $error->twitter_error($obj) if $obj;

    die $error;
}

__PACKAGE__->meta->make_immutable(inline_constructor => 0);


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
