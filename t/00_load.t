#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Net::Twitter' );
}

diag( "Testing Net::Twitter $Net::Twitter::VERSION, Perl $], $^X" );
