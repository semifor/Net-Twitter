use Test::More;
use Net::Twitter;
use URI;

sub test_uris {
    my ( $nt, $urls ) = @_;

    for my $attr ( keys %$urls ) {
        my $uri = $nt->$attr;
        ok $uri->isa('URI'), "$attr isa URI";
        is "$uri", $urls->{$attr}, "$attr is expected url";
    }
};

subtest 'default URL attributes' => sub {

    my %urls = (
        authentication_url => 'https://api.twitter.com/oauth/authenticate',
        authorization_url  => 'https://api.twitter.com/oauth/authorize',
        request_token_url  => 'https://api.twitter.com/oauth/request_token',
        access_token_url   => 'https://api.twitter.com/oauth/access_token',
        xauth_url          => 'https://api.twitter.com/oauth/access_token',
    );

    my $nt = Net::Twitter->new(
        traits          => [ qw/API::RESTv1_1 OAuth/ ],
        consumer_key    => 'key',
        consumer_secret => 'secret',
    );

    test_uris($nt, \%urls);
};

subtest 'explicit URL attributes' => sub {

    my %urls = (
        authentication_url => 'https://example.com/authenticate',
        authorization_url  => 'https://example.com/authorize',
        request_token_url  => 'https://example.com/request',
        access_token_url   => 'https://example.com/access',
        xauth_url          => 'https://example.com/xauth',
    );

    my $nt = Net::Twitter->new(
        traits          => [ qw/API::RESTv1_1 OAuth/ ],
        consumer_key    => 'key',
        consumer_secret => 'secret',
        %urls,
    );

    test_uris($nt, \%urls);
};

subtest 'with URIs' => sub {

    my %urls = (
        authentication_url => URI->new('https://example.com/authenticate'),
        authorization_url  => URI->new('https://example.com/authorize'),
        request_token_url  => URI->new('https://example.com/request'),
        access_token_url   => URI->new('https://example.com/access'),
        xauth_url          => URI->new('https://example.com/xauth'),
    );

    my $nt = Net::Twitter->new(
        traits          => [ qw/API::RESTv1_1 OAuth/ ],
        consumer_key    => 'key',
        consumer_secret => 'secret',
        %urls,
    );

    test_uris($nt, \%urls);
};

subtest 'oauth_urls pseudo attribute' => sub {

    my %urls = (
        authentication_url => 'https://example.com/authenticate',
        authorization_url  => 'https://example.com/authorize',
        request_token_url  => 'https://example.com/request',
        access_token_url   => 'https://example.com/access',
        xauth_url          => 'https://example.com/xauth',
    );

    my $nt = Net::Twitter->new(
        traits => [ qw/API::RESTv1_1 OAuth/ ],
        consumer_key    => 'key',
        consumer_secret => 'secret',
        oauth_urls      => \%urls,
    );

    test_uris($nt, \%urls);
};

subtest 'AppAuth URLs' => sub {

    my %urls = (
        request_token_url    => "https://api.twitter.com/oauth2/token",
        invalidate_token_url => "https://api.twitter.com/oauth2/invalidate_token",
    );

    my $nt = Net::Twitter->new(
        traits => [ qw/API::RESTv1_1 AppAuth/ ],
        consumer_key    => 'key',
        consumer_secret => 'secret',
    );

    test_uris($nt, \%urls);
};

done_testing;
