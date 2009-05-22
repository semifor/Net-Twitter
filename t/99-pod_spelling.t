#!perl -w
use strict;
use warnings;
use Test::More;

plan skip_all => 'set TEST_AUTHOR to enable this test' unless $ENV{TEST_AUTHOR};

eval 'use Test::Spelling 0.11';
plan skip_all => 'Test::Spelling 0.11 not installed' if $@;

set_spell_cmd('aspell list');

add_stopwords(<DATA>);

all_pod_files_spelling_ok();

__DATA__
ACKNOWLEDGEMENTS
API
APIs
BasicUser
DirectMessage
ExtendedUser
IM
IP
IRC
JSON
Laconica
Marc
Mims
Prather
RateLimitStatus
SMS
Str
Twitter
TwitterVision
Un
WrapError
apihost
apirealm
apiurl
clientname
clienturl
clientver
favorited
friended
geocode
identica
inline
lang
multipart
ok
params
perigrin
requester's
rpp
stringifies
timeline
twitterpm
ua
un
unfollow
url
useragent
username
