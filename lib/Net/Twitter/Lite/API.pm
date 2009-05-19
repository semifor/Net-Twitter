package Net::Twitter::Lite::API;

use Moose::Role;
use Carp;

requires qw/definition base_url/;

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

sub method_definitions {
    my ($class) = @_;

    return { map { $_->[0] => $_->[1] } map @{$_->[1]}, @{$class->definition} };
}

sub import {
    my $class = shift;

    my $target = caller(0);

    my $method_definitions = $class->method_definitions;
    while ( my ($method, $def) = each %$method_definitions ) {
        my ($arg_names, $path) = @{$def}{qw/required path/};
        $arg_names = $def->{params} if @$arg_names == 0 && @{$def->{params}} == 1;
        my $request = $def->{method} eq 'POST' ? $post_request : $get_request;

        my $modify_path = $path =~ s,/id$,/, ? $with_url_arg : sub { $_[0] };

        my $code = sub {
            my $self = shift;

            my $args = {};
            if ( ref $_[0] ) {
                UNIVERSAL::isa($_[0], 'HASH') && @_ == 1 || croak "$method expected a single HASH ref argument";
                $args = { %{shift()} }; # copy callers args since we may add ->{source}
            }
            elsif ( @_ ) {
                @_ == @$arg_names || croak "$method expected @{[ scalar @$arg_names ]} args";
                @{$args}{@$arg_names} = @_;
            }
            $args->{source} ||= $self->source if $method eq 'update';

            my $local_path = $modify_path->($path, $args);
            ###my $uri = URI->new($self->apiurl . "/$local_path.json");
            my $uri = URI->new($class->base_url->($self) . "/$local_path.json");
            return $self->parse_result($request->($self->_ua, $uri, $args));
        };

        $target->meta->add_method($_, $code) for ( $method, @{$def->{aliases} || []});
    }
}

1;

__END__

=head1 NAME

Net::Twitter::Lite::API - A definition of the Twitter API in a perl data structure

=head1 SYNOPSIS

    use aliased 'Net::Twitter::Lite::API::REST';

    my $api_def = API->definition;

=head1 DESCRIPTION

B<Net::Twitter::Lite::API> is the base class for classes providing API
definitions. It is used by the Net::Twitter::Lite distribution to dynamically
build methods, documentation, and tests.

=head1 METHODS

=head2 base_url

Returns the base URL for the API.

=head2 definition_url

Returns the API definition in the following form:

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

A string containing text describing the Twitter API call suitable for use in
documentation.

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

=head2 method_definitions

This method returns a HASH ref where the keys are method names and the values are individual
method definitions as described above for the API specified by the optional $api_name
argument.

=head1 SEE ALSO

=over 4

=item L<Net::Twitter::Lite>

Net::Twitter::Lite::API was written for the use of this module and its distribution.

=item L<http://apiwiki.twitter.com/>

The Twitter API documentation.

=back

=head1 AUTHOR

Marc Mims <marc@questright.com>

=head1 LICENSE

Copyright (c) 2009 Marc Mims

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
