use inc::Module::Install;

# MAINTAINER only exists in the repository (i.e., development) version of the
# project. This eliminates the need for a "require 'Template'".  TT2 is only
# needed to prepare a distribution.  It is not necessary for making, testing,
# or installing the CPAN module.
#
# To build lib/Net/Twitter/Lite.pm from src/net-twitter-lite-pm.tt2, touch
# MAINTAINER, the run "perl Makefile.PL"
system("$^X src/build.pl") if -e 'MAINTAINER';

name        'Net-Twitter-Lite';
all_from    'lib/Net/Twitter/Lite.pm';

no_index    directory => 'src';

requires    'Moose';
requires    'JSON::Any';
requires    'URI::Escape';
requires    'Exception::Class';
recommends  'JSON::XS';

eval {
    system 'pod2text lib/Net/Twitter/Lite.pm > README';
};

WriteAll;
