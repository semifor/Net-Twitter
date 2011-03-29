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
Akira
AutoCursor
BasicUser
CPAN
DateTime
DirectMessage
EOT
Etcheverry
ExtendedUser
GPS
Grennan
IM
IP
IRC
Identi
InflateObjects
JSON
KATOU
Laconica
Marc
Mims
Miyagawa
OAuth
OMG
Prather
RateLimit
RateLimitStatus
RetryOnError
Retweets
SMS
SSL
SavedSearch
Str
Tatsuhiko
Twitter
TwitterVision
Un
Unsubscribes
WOEID
WiFi
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
geo
geocode
granularities
identi
identica
inline
lang
multipart
netrc
oauth
ok
online
parameterized
params
perigrin
Pecorella
refactored
requester's
return's
retweet
retweeted
retweeting
retweets
rpp
spammer
ssl
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
woeid
xAuth
