#!perl
use warnings;
use strict;
use Try::Tiny;
use Test::More;
use Encode qw/decode encode_utf8 decode_utf8/;
use Net::Twitter;

eval "use LWP::UserAgent 5.819";
plan skip_all => 'LWP::UserAgent >= 5.819 required' if $@;

plan tests => 12;

my $req;
my $ua = LWP::UserAgent->new;
$ua->add_handler(request_send => sub {
    $req = shift;
    return HTTP::Response->new(200);
});

sub raw_sent_status {
    my $uri = URI->new;
    $uri->query($req->content);
    my %params = $uri->query_form;
    return $params{status};
}

sub sent_status { decode_utf8 raw_sent_status() }

my $nt = Net::Twitter->new(
    traits          => [qw/API::REST OAuth/],
    consumer_key    => 'key',
    consumer_secret => 'secret',
    ua              => $ua,
);
$nt->access_token('token');
$nt->access_token_secret('secret');

my $meta = $nt->meta;
$meta->make_mutable;
$meta->add_around_method_modifier('_make_oauth_request', sub {
		my ($orig, $self, $type, %args) = @_;

		ok utf8::is_utf8($args{extra_params}{status}), "status must be decoded";
		$self->$orig($type, %args);
	});
$meta->make_immutable;

# "Hello world!" in traditional Chinese if Google translate is correct
my $status = "\x{4E16}\x{754C}\x{60A8}\x{597D}\x{FF01}";

ok utf8::is_utf8($status), 'status parameter is decoded';

try { $nt->update($status) };

is sent_status(), $status, 'sent status matches update parameter';

# ISO-8859-1
my $latin1 = "\xabHello, world\xbb";

ok !utf8::is_utf8($latin1), "latin-1 string is not utf8 internally";
try { $nt->update($latin1) };
is sent_status(), $latin1, "latin-1 matches";
ok !utf8::is_utf8($latin1), "latin-1 not promoted to utf8";

### Net::Twitter expects decoded characters, not encoded bytes
### So, sending encoded utf8 to Net::Twitter will result in double
### encoded data.

SKIP: {
    eval "use Encode::DoubleEncodedUTF8";
    skip "requires Encode::DoubleEncodedUTF8", 3 if $@;

    try { $nt->update(encode_utf8 $status) };

    my $bytes = raw_sent_status();

    isnt $bytes, encode_utf8($status), "encoded status does not match";
    is   decode('utf-8-de', $bytes), $status, "double encoded";
};

############################################################
# Basic Auth
############################################################

$nt = Net::Twitter->new(
    legacy   => 0,
    username => 'fred',
    password => 'pebbles',
    ua       => $ua,
);

try { $nt->update($status) };
is sent_status(), $status, 'basic auth';

try { $nt->update($latin1) };
is sent_status(), $latin1, 'latin-1 basic auth';
