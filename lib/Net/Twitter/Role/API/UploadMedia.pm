package Net::Twitter::Role::API::UploadMedia;

use Moose::Role;
use Net::Twitter::API;
use DateTime::Format::Strptime;
use URI;

has upload_url => isa => 'Str', is => 'ro', default => 'http://upload.twitter.com/1.1';

after BUILD => sub {
    my $self = shift;

    $self->{upload_url} =~ s/^http:/https:/ if $self->ssl;
};

base_url     'upload_url';
authenticate 1;

twitter_api_method upload => (
    path        => 'media/upload',
    method      => 'POST',
    params      => [qw/media/],
    required    => [qw/media/],
    booleans    => [qw/possibly_sensitive display_coordinates/],
    returns     => 'Image',
    description => 'Upload images to twitter without posting them on the timeline'
);

1;

__END__

=head1 NAME

Net::Twitter::Role::API::UploadImage - A definition of the Twitter Upload API as a Moose role

=head1 SYNOPSIS

  package My::Twitter;
  use Moose;
  with 'Net::Twitter::API::UploadImage';

=head1 DESCRIPTION

This module provides definitions the Twitter Upload API methods.

