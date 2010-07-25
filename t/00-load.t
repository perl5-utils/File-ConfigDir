#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::ConfigDir' ) || print "Bail out!
";
}

diag( "Testing File::ConfigDir $File::ConfigDir::VERSION, Perl $], $^X" );
