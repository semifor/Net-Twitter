#!perl
use warnings;
use strict;
use Test::More tests => 9;
use Test::Exception;
use lib qw(t/lib);
use Mock::LWP::UserAgent;
use Net::Twitter::Lite;

my $nt = Net::Twitter::Lite->new(
    username => 'homer',
    password => 'doh!',
);

my $ua = $nt->_ua;


# simulate an error returned by the twitter API
$ua->set_response({
    code    => 404,
    message => 'Not Found',
    content => {
        request => '/direct_messages/destroy/456.json',
        error   => 'No direct message with that ID found.',
    },
});

dies_ok { $nt->destroy_direct_message(456) } 'TwitterException';
my $e = TwitterException->caught();
isa_ok $e, 'TwitterException';
like   $e->error, qr/No direct message/, 'repsonse message';
is     $e->http_response->code, 404, "respose code";
like   $e->twitter_error->{request}, qr/456.json/, 'twitter_error request';


# simulate a 500 response returned by LWP::UserAgent when it can't make a connection
$ua->set_response({
    code    => 500,
    message => "Can't connect to twitter.com:80",
    content => "<html>foo</html>",
});

dies_ok { $nt->friends_timeline({ since_id => 500_000_000 }) } 'HttpException';
$e = Exception::Class->caught();
isa_ok $e, 'HttpException';
like    $e->http_response->content, qr/html/, 'html content';

# test the synopsis usage
eval { die "not a Net::Twitter::Lite exception" };
if ( $@ ) {
    if ( my $e = TwitterException->caught() ) {
        1;
    }
    elsif ( $e = HttpException->caught() ) {
        1;
    }
    else {
        like $@, qr/not a Net::Twitter::Lite exception/, 'regular exception';
    }
}

exit 0;
