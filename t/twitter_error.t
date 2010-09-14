#!perl
use warnings;
use strict;
use Test::More tests => 4;
use Net::Twitter::Error;
use HTTP::Response;

{
    # old school error
    my $res = HTTP::Response->new(400);

    my $e = Net::Twitter::Error->new(
        http_response => $res,
        twitter_error => { error => "Something wicked" },
    );

    like $e, qr/Something wicked/, 'old school twitter error';
}

{
    # newer variant
    my $res = HTTP::Response->new(400);

    my $e = Net::Twitter::Error->new(
        http_response => $res,
        twitter_error => { error => { message => "Something wicked" } },
    );

    like $e, qr/Something wicked/, 'twitter error with message/code';
}

{
    # array of errors variant
    my $res = HTTP::Response->new(400);

    my $e = Net::Twitter::Error->new(
        http_response => $res,
        twitter_error => { errors => [{ message => "Something wicked" }] },
    );

    like $e, qr/Something wicked/, 'twitter array of errors';
}

{
    # unexpected
    my $res = HTTP::Response->new(400);

    my $e = Net::Twitter::Error->new(
        http_response => $res,
    );

    like $e, qr/Bad Request/, 'twitter array of errors';
}
