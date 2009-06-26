use inc::Module::Install;

version_from      'lib/Net/Twitter/Core.pm';
perl_version_from 'lib/Net/Twitter/Core.pm';

# MAINTAINER only exists in the repository (i.e., development) version of the
# project. This eliminates the need for a "require 'Template'".  TT2 is only
# needed to prepare a distribution.  It is not necessary for making, testing,
# or installing the CPAN module.
#
# To build lib/Net/Twitter/Lite.pm from src/net-twitter-lite-pm.tt2, touch
# MAINTAINER, the run "perl Makefile.PL"
system($^X, "src/build.pl", version, 'src/net-twitter-pod.tt2', 'lib/Net/Twitter.pod')
    if -e 'MAINTAINER';

name        'Net-Twitter';
all_from    'lib/Net/Twitter.pod';
requires    'Moose' => 0.85;
requires    'JSON::Any' => 1.19;
requires    'URI::Escape';
requires    'namespace::autoclean';
requires    'Net::OAuth'     => 0.16;
requires    'LWP::UserAgent' => 2.032;
requires    'MooseX::MultiInitArg';
recommends  'JSON::XS';

no_index    directory => 'src';
no_index    directory => 'examples';

# resources
repository 'git://github.com/semifor/Net-Twitter.git';
homepage   'http://github.com/semifor/Net-Twitter';
bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=Net-Twitter';

eval {
    system 'pod2text lib/Net/Twitter.pod > README';
};

auto_install;

WriteAll;
