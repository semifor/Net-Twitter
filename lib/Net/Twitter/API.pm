package Net::Twitter::API;
use Moose ();
use Carp;
use Moose::Exporter;
use URI::Escape;
use Encode ();

use namespace::autoclean;

Moose::Exporter->setup_import_methods(
    with_caller => [ 'base_url', 'twitter_api_method' ],
);

my $post_request = sub {
    my ($ua, $uri, $args) = @_;
    return $ua->post($uri, $args);
};

my $get_request = sub {
    my ($ua, $uri, $args) = @_;
    $uri->query_form($args);
    return $ua->get($uri);
};

my $with_url_arg = sub {
    my ($path, $args) = @_;

    if ( defined(my $id = delete $args->{id}) ) {
        $path .= uri_escape($id);
    }
    else {
        chop($path);
    }
    return $path;
};

sub twitter_api_method {
    my ($caller, $name, %options) = @_;

    my $class = Moose::Meta::Class->initialize($caller);

    my ($arg_names, $path) = @options{qw/required path/};
    $arg_names = $options{params} if @$arg_names == 0 && @{$options{params}} == 1;
    my $request = $options{method} eq 'POST' ? $post_request : $get_request;

    my $modify_path = $path =~ s,/id$,/, ? $with_url_arg : sub { $_[0] };

    my $code = sub {
        my $self = shift;

        my $args = {};
        if ( ref $_[0] ) {
            UNIVERSAL::isa($_[0], 'HASH') && @_ == 1 || croak "$name expected a single HASH ref argument";
            $args = { %{shift()} }; # copy callers args since we may add ->{source}
        }
        elsif ( @_ ) {
            @_ == @$arg_names || croak "$name expected @{[ scalar @$arg_names ]} args";
            @{$args}{@$arg_names} = @_;
        }
        $args->{source} ||= $self->source if $options{add_source};

        my $local_path = $modify_path->($path, $args);
        
        my $uri = URI->new($caller->_base_url($self) . "/$local_path.json");

        # UTF-8 encode get/post parameters
        @{$args}{keys %$args} = map { Encode::encode('UTF-8', $_) } values %$args;

        return $self->_parse_result($request->($self->ua, $uri, $args));
    };

    $class->add_method(
        $name,
        Net::Twitter::Meta::Method->new(
            name => $name,
            package_name => $caller,
            body => $code,
            %options,
        ),
    );

    $class->add_method($_, $code) for @{$options{aliases} || []};
}

sub base_url {
    my ($caller, $name, %options) = @_;
    
    Moose::Meta::Class->initialize($caller)->add_method(_base_url => sub { $_[1]->$name });
}


package Net::Twitter::Meta::Method;
use Moose;
extends 'Moose::Meta::Method';

use namespace::clean;

has description => ( isa => 'Str', is => 'ro', required => 1 );
has aliases     => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] } );
has path        => ( isa => 'Str', is => 'ro', required => 1 );
has method      => ( isa => 'Str', is => 'ro', default => 'GET' );
has add_source  => ( isa => 'Bool', is => 'ro', default => 0 );
has params      => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] } );
has required    => ( isa => 'ArrayRef[Str]', is => 'ro', default => sub { [] } );
has returns     => ( isa => 'Str', is => 'ro', predicate => 'has_returns' );
has deprecated  => ( isa => 'Bool', is => 'ro', default => 0 );

sub new { shift->SUPER::wrap(@_) }

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
of the Net-Twitter distribution on CPAN and is used by C<Net::Twitter::API::REST>,
C<Net::Twitter::API::Search>, and perhaps others.

It's intent is to make maintaining C<Net::Twitter> as easy as possible.

=head1 METHODS

=over 4

=item base_url

Specifies, by name, the attribute which contains the base URL for the defined API.

=item twitter_api_method

Defines a Twitter API method.  Valid arguments are:

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
