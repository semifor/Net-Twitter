use inc::Module::Install;

all_from    'lib/Net/Twitter/Lite.pm';
requires    'Moose';
requires    'JSON::Any';
requires    'URI::Escape';
requires    'Exception::Class';
recommends  'JSON::XS';

no_index    directory => 'src';

# resources
repository 'git://github.com/semifor/net-twitter-lite.git';
homepage   'http://github.com/semifor/net-twitter-lite/tree/master';

# MAINTAINER only exists in the repository (i.e., development) version of the
# project. This eliminates the need for a "require 'Template'".  TT2 is only
# needed to prepare a distribution.  It is not necessary for making, testing,
# or installing the CPAN module.
#
# To build lib/Net/Twitter/Lite.pm from src/net-twitter-lite-pm.tt2, touch
# MAINTAINER, the run "perl Makefile.PL"
system("$^X src/build.pl " . version) if -e 'MAINTAINER';

eval {
    system 'pod2text lib/Net/Twitter/Lite.pod > README';
};

WriteAll;
