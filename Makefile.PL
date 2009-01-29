use inc::Module::Install;

name        'Net-Twitter-Lite';
all_from    'lib/Net/Twitter/Lite.pm';

requires    'Moose';
requires    'JSON::Any';
requires    'URI::Escape';
requires    'Exception::Class';
recommends  'JSON::XS';

eval {
    system 'pod2text lib/Net/Twitter/Lite.pm > README';
};

WriteAll;
