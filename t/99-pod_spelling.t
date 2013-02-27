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

all_pod_files_spelling_ok(qw/lib src/);

__DATA__
ACKNOWLEDGEMENTS
Akira
API
api
APIDOC
apihost
apirealm
APIs
apiurl
AutoCursor
BasicUser
blogging
clientname
clienturl
clientver
contributees
CPAN
cursored
Cursoring
cursoring
DateTime
DirectMessage
dzil
EOT
Etcheverry
ExtendedUser
favorited
friended
geo
geocode
GPS
granularities
Grennan
Haim
Identi
identi
identica
IM
InflateObjects
inline
IP
ip
IRC
JSON
KATOU
Laconica
lang
Marc
MERCHANTABILITY
Mims
Miyagawa
multipart
netrc
OAuth
oauth
oembed
oEmbed
ok
OMG
online
parameterized
params
Pecorella
perigrin
Prather
RateLimit
RateLimitStatus
refactored
reimplemented
requester's
RetryOnError
return's
retweet
retweeted
retweeting
Retweets
retweets
rpp
RWD
SavedSearch
SMS
spammer
SSL
ssl
Str
stringifies
Tatsuhiko
timeline
tvhost
tvrealm
tvurl
Twitter
Twitter's
twitterpm
TwitterVision
twittervision
ua
Un
un
unfollow
Unsubscribes
URI
url
useragent
username
usernames
WiFi
WOEID
woeid
WrapError
xAuth
