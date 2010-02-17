#!perl
use warnings;
use strict;
use Try::Tiny;
use Test::More;
use Encode qw/decode encode_utf8 decode_utf8/;
use Net::Twitter;

eval "use LWP::UserAgent 5.819";
plan skip_all => 'LWP::UserAgent >= 5.819 required' if $@;

my $nt = Net::Twitter->new(
    traits          => [qw/API::REST OAuth/],
    consumer_key    => 'key',
    consumer_secret => 'secret',
);
$nt->access_token('token');
$nt->access_token_secret('secret');

my $req;
$nt->ua->add_handler(request_send => sub {
    $req = shift;
    return HTTP::Response->new(200);
});

# "Hello world!" in traditional Chinese if Google translate is correct
my $status = "\x{4E16}\x{754C}\x{60A8}\x{597D}\x{FF01}";

ok utf8::is_utf8($status), 'status parameter is decoded';

try { $nt->update($status) };

my $uri = URI->new;
$uri->query($req->content);

my %params = $uri->query_form;
my $sent_status = decode_utf8 $params{status};

is $sent_status, $status, 'sent status matches update parameter';

### Net::Twitter expects decoded characters, not encoded bytes
### So, sending encoded utf8 to Net::Twitter will result in double
### encoded data.

SKIP: {
    eval "use Encode::DoubleEncodedUTF8";
    skip "requires Encode::DoubleEncodedUTF8" if $@;

    try { $nt->update(encode_utf8 $status) };

    $uri = URI->new;
    $uri->query($req->content);
    %params = $uri->query_form;

    isnt $params{status}, encode_utf8($status), "encoded status does not match";
    is   decode('utf-8-de', $params{status}), $status, "double encoded";
};
