package Net::Twitter::API;
use Moose ();
use Carp::Clan qw/^Net::Twitter/;
use Moose::Exporter;
use URI::Escape;
use DateTime::Format::Strptime;

use namespace::autoclean;

Moose::Exporter->setup_import_methods(
    with_caller => [ qw/base_url authenticate datetime_parser twitter_api_method/ ],
);

my $_base_url;
sub base_url { $_base_url = $_[1] }

# kludge: This is very transient!
my $do_auth;
sub authenticate { $do_auth = $_[1] }

# provide a default: we'll use the format of the REST API
my $datetime_parser = DateTime::Format::Strptime->new(pattern => '%a %b %d %T %z %Y');
sub datetime_parser { $datetime_parser = $_[1] }

sub twitter_api_method {
    my $caller = shift;
    my $name   = shift;
    my %options = (
        authenticate    => $do_auth,
        datetime_parser => $datetime_parser,
        base_url_method => $_base_url,
        @_,
    );
    my $dblencode = delete $options{dblencode};

    my $deprecation_coderef = ref $options{deprecated} eq ref sub {}
                            ? sub { $options{deprecated}->($name) }
                            : sub {};

    my $class = Moose::Meta::Class->initialize($caller);

    my ($arg_names, $path) = @options{qw/required path/};
    $arg_names = $options{params} if @$arg_names == 0 && @{$options{params}} == 1;

    my $code = sub {
        my $self = shift;

        # give the deprecation coderef early access in case it intends to die
        $deprecation_coderef->();

        # copy callers args since we may add ->{source}
        my $args = ref $_[-1] eq 'HASH' ? { %{pop @_} } : {};

        # flatten array arguments
        for ( qw/user_id screen_name/ ) {
            $args->{$_} = join ',' => @{ $args->{$_} } if ref $args->{$_} eq 'ARRAY';
        }

        $self->_remap_legacy_synthetic_args($args);

        croak sprintf "$name expected %d args", scalar @$arg_names if @_ > @$arg_names;

        # promote positional args to named args
        for ( my $i = 0; @_; ++$i ) {
            my $param = $arg_names->[$i];
            croak "duplicate param $param: both positional and named"
                if exists $args->{$param};

            $args->{$param} = shift;
        }

        $args->{source} ||= $self->source if $options{add_source};

        my $authenticate = exists $args->{-authenticate} ? $args->{-authenticate} : $options{authenticate};

        # promote boolean parameters
        for my $boolean_arg ( @{ $options{booleans} } ) {
            if ( exists $args->{$boolean_arg} ) {
                next if $args->{$boolean_arg} =~ /^true|false$/;
                $args->{$boolean_arg} = $args->{$boolean_arg} ? 'true' : 'false';
            }
        }

        # Workaround Twitter bug: any value passed for skip_user is treated as true.
        # The only way to get 'false' is to not pass the skip_user at all.
        delete $args->{skip_user} if exists $args->{skip_user} && $args->{skip_user} eq 'false';

        # replace placeholder arguments
        my $local_path = $path;
        $local_path =~ s,/:id$,, unless exists $args->{id}; # remove optional trailing id
        $local_path =~ s/:(\w+)/delete $args->{$1} or croak "required arg '$1' missing"/eg;

        my $uri = URI->new($self->${ \$options{base_url_method} } . "/$local_path.json");
        return $self->_json_request(
            $options{method},
            $uri,
            $args,
            $authenticate,
            $options{datetime_parser},
            $dblencode,
            $path,
        );
    };

    $class->add_method(
        $name,
        Net::Twitter::Meta::Method->new(
            name         => $name,
            package_name => $caller,
            body         => $code,
            %options,
        ),
    );

    $class->add_method($_, $code) for @{$options{aliases} || []};
}

package Net::Twitter::Meta::Method;
use Moose;
use Carp::Clan qw/^Net::Twitter/;
extends 'Moose::Meta::Method';

use namespace::autoclean;

has description => ( isa => 'Str', is => 'ro', required => 1 );
has aliases     => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] } );
has path        => ( isa => 'Str', is => 'ro', required => 1 );
has method      => ( isa => 'Str', is => 'ro', default => 'GET' );
has add_source  => ( isa => 'Bool', is => 'ro', default => 0 );
has params      => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] } );
has required    => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] } );
has returns     => ( isa => 'Str', is => 'ro', predicate => 'has_returns' );
has deprecated  => ( isa => 'Bool|CodeRef', is => 'ro', default => 0 );
has booleans    => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] } );
has authenticate => ( isa => 'Bool', is => 'ro', required => 1 );
has datetime_parser => ( is => 'ro', required => 1 );
has base_url_method => ( isa => 'Str', is => 'ro', required => 1 );

# TODO: can MooseX::StrictConstructor be made to work here?
my %valid_attribute_names = map { $_->init_arg => 1 }
                            __PACKAGE__->meta->get_all_attributes;

sub new {
    my $class = shift;
    my %args  = @_;

    my @invalid_attributes = grep { !$valid_attribute_names{$_} } keys %args;
    croak "unexpected argument(s): @invalid_attributes" if @invalid_attributes;

    $class->SUPER::wrap(@_);
}

1;

__END__

=head1 NAME

Net::Twitter::API - Moose sugar for defining Twitter API methods

=head1 SYNOPSIS

  package My::Twitter::API;
  use Moose::Role;
  use Net::Twitter::API;

  use namespace::autoclean;

  has apiurl => ( isa => 'Str', is => 'rw', default => 'http://twitter.com' );

  base_url 'apiurl';

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

  1;

=head1 DESCRIPTION

This module provides some Moose sugar for defining Twitter API methods.  It is part
of the Net-Twitter distribution on CPAN and is used by C<Net::Twitter::API::RESTv1_1>,
C<Net::Twitter::API::Search>, and perhaps others.

It's intent is to make maintaining C<Net::Twitter> as easy as possible.

=head1 METHODS

=over 4

=item base_url

Specifies, by name, the attribute which contains the base URL for the defined API.

=item twitter_api_method

Defines a Twitter API method.  Valid arguments are:

=item authenticate

Specifies whether, by default, API methods calls should authenticate.

=item datetime_parser

Specifies the Date::Time::Format derived parser to use for parsing and
formatting date strings for the API being defined.

=over 4

=item description

A string describing the method, suitable for documentation.

=item aliases

An ARRAY ref of strings containing alternate names for the method.

=item path

A string containing the path part of the API URL

=item method

A string containing the HTTP method for the call.  Defaults to "GET".

=item add_source

A boolean, indicating whether or not the C<source> parameter should be added
to the API call.  (The source value is assigned by Twitter for registered
applications.)  Defaults to 0.

=item params

An ARRAY ref of strings naming all of the valid parameters.  Defaults to an
empty ARRAY ref.

=item required

An ARRAY ref of strings naming all of the required parameters.  Defaults to an
empty ARRAY ref.

=item returns

A string describing the return type of the API method call.

=item deprecated

A boolean indicating whether or not this API is deprecated.  If set to 1, code
for the method will be created.  This option is optional, and is used by the
C<Net-Twitter> distribution when generating documentation.  It defaults to 0.

=back

=back

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
