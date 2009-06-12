#!perl -w
use strict;
use warnings;
use Test::More;

plan skip_all => 'set TEST_POD to enable this test'
  unless ($ENV{TEST_POD} || -e 'MANIFEST.SKIP');

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
CPAN
DirectMessage
ExtendedUser
Grennan
Identi
IM
IP
IRC
JSON
Laconica
Marc
Mims
Miyagawa
OAuth
OMG
oauth
Prather
RateLimitStatus
refactored
SavedSearch
SMS
Str
Tatsuhiko
Twitter
TwitterVision
Un
WrapError
apihost
apirealm
apiurl
blogging
clientname
clienturl
clientver
favorited
friended
geocode
identi
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
tvhost
tvrealm
tvurl
twitterpm
twittervision
ua
un
unfollow
url
useragent
username
