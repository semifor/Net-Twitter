use inc::Module::Install;

version_from      'lib/Net/Twitter/Core.pm';
perl_version_from 'lib/Net/Twitter/Core.pm';

if ( $Module::Install::AUTHOR ) {
    system $^X, "src/build.pl", version, 'src/net-twitter-pod.tt2', 'lib/Net/Twitter.pod';
    system 'pod2text lib/Net/Twitter.pod > README';
}

name        'Net-Twitter';
all_from    'lib/Net/Twitter.pod';

# core
requires    'Carp';
requires    'Digest::SHA';

# CPAN
requires    'HTTP::Request::Common';
requires    'JSON::Any'                 => 1.21;
requires    'LWP::UserAgent'            => 2.032;
requires    'Moose'                     => 0.85;
requires    'Moose::Exporter';
requires    'Moose::Role';
requires    'MooseX::MultiInitArg';
requires    'namespace::autoclean';
requires    'Net::OAuth'                => 0.16;
requires    'URI';
requires    'URI::Escape';

# Don't rely on the JSON::Any requirement to pull in a suitable JSON backend.
# The user may already have JSON::Any installed, but since removed all valid
# providers.  (Yes, this seems to have happened in the wild.)
sub has_json_handler () {
    my @order = qw/JSON::XS JSON::DWIW JSON/;
    for my $provider ( @order ) {
        eval "require $provider";
        return 1 unless $@;
    }
    return;
}

has_json_handler || requires JSON => '2.02';

no_index    directory => 'src';
no_index    directory => 'examples';

# resources
homepage   'http://github.com/semifor/Net-Twitter';
bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=Net-Twitter';

auto_set_repository;
auto_manifest;
auto_install;

WriteAll;
