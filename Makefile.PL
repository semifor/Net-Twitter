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
requires    'File::Spec';
requires    'List::Util';
requires    'Net::Netrc';
requires    'Scalar::Util';

# CPAN
requires    'Crypt::SSLeay'             => 0.50;

requires    'Data::Visitor::Callback';
requires    'DateTime'                  => 0.51;
requires    'DateTime::Format::Strptime'=> 1.09;
requires    'Devel::StackTrace'         => 1.21;
requires    'Digest::HMAC_SHA1';
requires    'Encode';
requires    'HTML::Entities';
requires    'HTTP::Request::Common';
requires    'JSON::Any'                 => 1.21;
requires    'LWP::UserAgent'            => 2.032;
requires    'Moose'                     => 0.90;
requires    'Moose::Exporter';
requires    'Moose::Role';
requires    'MooseX::MultiInitArg';
requires    'namespace::autoclean'      => 0.09;
requires    'Net::OAuth'                => 0.25;
requires    'Scalar::Util';
requires    'Time::HiRes';
requires    'URI'                       => 1.40;
requires    'URI::Escape';
requires    'Try::Tiny'                 => 0.03;

test_requires 'Test::Exception';
test_requires 'Test::More' => 0.88; # for done_testing

# Don't rely on the JSON::Any requirement to pull in a suitable JSON backend.
# The user may already have JSON::Any installed, but since removed all valid
# providers.  (Yes, this seems to have happened in the wild.)
sub has_json_xs () {
    my @order = qw/JSON::XS/;
    for my $provider ( @order ) {
        eval "require $provider";
        return 1 unless $@;
    }
    return;
}

if (has_json_xs()) {
  requires 'JSON::XS' => 0;
} else {
  requires 'JSON' => '2.02';
}

no_index    directory => 'src';
no_index    directory => 'examples';

# resources
homepage   'http://github.com/semifor/Net-Twitter';
bugtracker 'http://rt.cpan.org/Public/Dist/Display.html?Name=Net-Twitter';

auto_set_repository;
auto_manifest;
auto_install;

WriteAll;
