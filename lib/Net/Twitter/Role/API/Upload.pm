package Net::Twitter::Role::API::Upload;
use Moose::Role;
use Net::Twitter::API;
use DateTime::Format::Strptime;
use URI;

has upload_url => isa => 'Str', is => 'ro', default => 'http://upload.twitter.com/1';

after BUILD => sub {
    my $self = shift;

    $self->{upload_url} =~ s/^http:/https:/ if $self->ssl;
};

base_url     'upload_url';
authenticate 1;

our $DATETIME_PARSER = DateTime::Format::Strptime->new(pattern => '%a %b %d %T %z %Y');
datetime_parser $DATETIME_PARSER;

twitter_api_method update_with_media => (
    path        => 'statuses/update_with_media',
    method      => 'POST',
    params      => [qw/
        status media[] possibly_sensitive in_reply_to_status_id lat long place_id display_coordinates
    /],
    required    => [qw/status media/],
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

1;

__END__

=head1 NAME

Net::Twitter::Role::API::Upload - A definition of the Twitter Upload API as a Moose role

=head1 SYNOPSIS

  package My::Twitter;
  use Moose;
  with 'Net::Twitter::API::Upload';

=head1 DESCRIPTION

This module provides definitions the Twitter Upload API methods.

=head1 AUTHOR

Allen Haim <allen@netherrealm.net>

Marc Mims <marc@questright.com>

=head1 LICENSE

Copyright (c) 2011 Marc Mims

The Twitter API itself, and the description text used in this module is:

Copyright (c) 2011 Twitter

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
