use inc::Module::Install;

# build lib/Net/Twitter/Lite.pm from TT2 template
system("$^X src/build.pl") if -e 'inc/.author';

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
