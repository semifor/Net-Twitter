#!perl
use warnings;
use strict;
use Test::More tests => 4;
use File::Spec;

{
    package Foo;
    use Moose;

    has net_twitter => is => 'rw', required => 1;

    sub whois {
        my ( $self, $id ) = @_;

        # $line follows, should be reported as frame 0 in the stack trace
        $self->net_twitter->show_user($id);
    }
}

my $line = __LINE__ - 4; # is there a better way to do this? 

use Net::Twitter;
use HTTP::Response;
use Try::Tiny;

my $nt = Net::Twitter->new(legacy => 0);

$nt->ua->add_handler(request_send => sub {
    my $res = HTTP::Response->new(403);
    $res->content('{"errors":[{"code":63,"message":"User has been suspended"}]}');
    $res;
});


my $foo = Foo->new(net_twitter => $nt);
try { $foo->whois(1234) }
catch {
    like $_->error, qr/suspended/, 'stringified error contains twitter error message';
    
    my $frame = $_->stack_trace->frame(0);
    my $file = File::Spec->canonpath(__FILE__);
    my $file_in_frame = File::Spec->canonpath($frame->{filename});
    is $file_in_frame, $file, "first stack frame file";
    is $frame->{line}, $line, "first stack frame line";
    like $_->error, qr( at \Q$file\E line $line$), 'error contains first stack frame';
};
