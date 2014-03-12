#!perl
use warnings;
use strict;
use Test::More tests => 8;
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
    is $e->twitter_error_text, 'Something wicked', 'twitter_error_text for old school twitter error';
}

{
    # newer variant
    my $res = HTTP::Response->new(400);

    my $e = Net::Twitter::Error->new(
        http_response => $res,
        twitter_error => { error => { message => "Something wicked" } },
    );

    like $e, qr/Something wicked/, 'twitter error with message/code';
    is $e->twitter_error_text, 'Something wicked', 'twitter_error_text for twitter error with message/code';
}

{
    # array of errors variant
    my $res = HTTP::Response->new(400);

    my $e = Net::Twitter::Error->new(
        http_response => $res,
        twitter_error => { errors => [{ message => "Something wicked" }] },
    );

    like $e, qr/Something wicked/, 'twitter array of errors';
    is $e->twitter_error_text, 'Something wicked', 'twitter_error_text for twitter array of errors';
}

{
    # unexpected
    my $res = HTTP::Response->new(400);

    my $e = Net::Twitter::Error->new(
        http_response => $res,
    );

    is $e->twitter_error_text, '', 'twitter_error_text is empty string';
    like $e, qr/Bad Request/, 'twitter array of errors';
}
