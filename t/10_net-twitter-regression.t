#!perl
use Carp;
use strict;
use Test::More;
use Test::Fatal;
use lib qw(t/lib);

{
    # simple mock object for Net::Netrc
    package # hide from PAUSE
        Net::Netrc;
    use Moose;
    sub lookup { shift->new }
    sub lpa { qw/fred bedrock/ }

    $INC{'Net/Netrc.pm'} = __FILE__;
}


eval 'use TestUA';
plan skip_all => 'LWP::UserAgent 5.819 required for tests' if $@;

use Net::Twitter;

my $nt = Net::Twitter->new(
    traits => [qw/API::REST/],
    username => 'homer',
    password => 'doh!',
);

my $t = TestUA->new(1, $nt->ua);

ok      $nt->friends_timeline,                        'friends_timeline no args';
ok      $nt->create_friend('flanders'),               'create_friend scalar arg';
ok      $nt->create_friend({ id => 'flanders' }),     'create_friend hashref';
ok      $nt->destroy_friend('flanders'),              'destroy_friend scalar arg';

$t->response->content('true');
my $r;

# back compat: 1.23 accepts scalar args
is exception { $r = $nt->relationship_exists('homer', 'marge') }, undef, 'relationship_exists scalar args';

ok       $r = $nt->relationship_exists({ user_a => 'homer', user_b => 'marge' }),
            'relationship_exists hashref';

# back compat: 1.23 returns bool
ok      $r, 'relationship_exists returns true';
$t->reset_response;

# Net::Twitter calls used by POE::Component::Server::Twirc
ok      $nt->new_direct_message({ user => 'marge', text => 'hello, world' }), 'new_direct_message';
ok      $nt->friends({page => 2}), 'friends';
cmp_ok  $t->arg('page'), '==', 2, 'page argument passed';
ok      $nt->followers({page => 2}), 'followers';
ok      $nt->direct_messages, 'direct_messages';
ok      $nt->direct_messages({ since_id => 1 }), 'direct_messages since_id';
ok      $nt->friends_timeline({ since_id => 1 }), 'friends_timeline since_id';
ok      $nt->replies({ since_id => 1 }), 'replies since_id';
ok      $nt->user_timeline, 'user_timeline';
ok      $nt->update('hello, world'), 'update';
ok      $nt->create_friend('flanders'), 'create_friend';
ok      $nt->relationship_exists('homer', 'flanders'), 'relationship exists scalar args';
ok      $nt->relationship_exists({ user_a => 'homer', user_b => 'flanders' }), 'relationship exists hashref';
ok      $nt->destroy_friend('flanders'), 'destroy_friend';
ok      $nt->create_block('flanders'), 'create_block';
ok      $nt->destroy_block('flanders'), 'destroy_block';
ok      $nt->create_favorite({ id => 12345678 }), 'create_favorite hashref';
ok      $nt->rate_limit_status, 'rate_limit_status';

### Regression: broken in 2.03
ok      $nt->show_status('flanders'),           'show_status string arg';
$t->add_id_arg('flanders');
is      $t->arg('id'),    'flanders',               'show_status ID set';

ok      $nt->show_user('marge'),     'show_user string arg';
$t->add_id_arg('marge');
is      $t->arg('id'), 'marge',         'show_user ID set';

ok      $nt->show_user({ id => 'homer' }),     'show_user hashref';
$t->add_id_arg('homer');
is      $t->arg('id'), 'homer',                    'show_user ID set 2';

ok      $nt->public_timeline, 'public_timeline blankargs';

### v3.09000 ### Role BUILD methods not called need after BUILD => sub {...}
$nt = Net::Twitter->new(ssl => 1, traits => [qw/API::REST API::Lists/]);
$t  = TestUA->new(1, $nt->ua);

$r  = $nt->home_timeline;
is    $t->request->uri->scheme, 'https', 'ssl used for REST';
$r  = $nt->list_lists('perl_api');
is    $t->request->uri->scheme, 'https', 'ssl used for Lists';

### v3.10001 ### netrc used $self->apiurl, which is only available via the API::REST trait
is exception  { Net::Twitter->new(netrc => 1, traits => [qw/API::Lists/]) }, undef, 'netrc with API::Lists lives';
### v3.11004 ### single array ref arg to update_profile_image not proprerly handled
$r  = $nt->update_profile_image([ undef, 'my_mug.jpg', Content_Type => 'image/jpeg', Content => '' ]);
is    $t->request->content_type, 'multipart/form-data', 'multipart/form-data';

done_testing
