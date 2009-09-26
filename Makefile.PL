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
requires    'Net::Netrc';
requires    'Scalar::Util';

# CPAN
requires    'Data::Visitor::Callback';
requires    'DateTime';
requires    'DateTime::Format::Strptime';
requires    'HTML::Entities';
requires    'HTTP::Request::Common';
requires    'JSON::Any'                 => 1.21;
requires    'LWP::UserAgent'            => 2.032;
requires    'Moose'                     => 0.85;
requires    'Moose::Exporter';
requires    'Moose::Role';
requires    'MooseX::AttributeHelpers';
requires    'MooseX::MultiInitArg';
requires    'namespace::autoclean'      => 0.09;
requires    'Net::OAuth'                => 0.16;
requires    'URI'                       => 1.40;
requires    'URI::Escape';

test_requires 'Test::More' => 0.88; # for done_testing

# Don't rely on the JSON::Any requirement to pull in a suitable JSON backend.
# The user may already have JSON::Any installed, but since removed all valid
# providers.  (Yes, this seems to have happened in the wild.)
sub has_json_handler () {
    my @order = qw/JSON::XS JSON/;
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
