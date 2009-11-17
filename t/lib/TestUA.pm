package # hide from PAUSE
    TestUA;

use strict;
use warnings;
use Carp;
use Scalar::Util qw/blessed/;
use HTTP::Response;
use LWP::UserAgent 5.819;

sub new {
    my ($class, $ua, $content) = @_;

    blessed $ua || croak 'Usage: TestUA->new($real_ua [, $content ])';

    my $self = bless { content => $content }, $class;
    $self->reset_response;

    $ua->add_handler(request_send => sub {
        $self->{request} = shift;

        $self->{response}->request($self->{request});

        # extract arguments from the request uri and content
        my $uri = $self->{request}->uri->clone;
        my %args = $uri->query_form;
        $uri->query($self->{request}->content);
        $self->{args} = { %args, $uri->query_form };

        return $self->{response};
    });

    return $self;
}

sub reset_response {
    my $self = shift;

    my $res = HTTP::Response->new(200, 'OK');
    $res->content($self->{content} || '{"test":"success"}');
    $self->{response} = $res;
}

sub arg {
    my ($self, $arg) = @_;

    return $self->{args}{$arg};
}

sub args { shift->{args} }

# An id can be passed in the URL body for some Twitter API calls; add the ID
# arg to the args list if it is in the path in the proper format
sub add_id_arg {
    my ($self, $id) = @_;
    
    $self->{args}{id} = $id if $self->path =~ /\/\Q$id\E\.json$/;
}

sub method { shift->{request}->method }

sub path {
   # hack! remove the api version portion of the path (if any)
   my $path = shift->{request}->uri->path;
   $path =~ s{/\d+(?=/)}{};
   return $path;
}

sub response {
    my $self = shift;

    $self->{response} = shift if @_;
    return $self->{response};
}

sub request { shift->{request} }

1;
