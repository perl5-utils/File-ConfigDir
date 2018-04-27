#!perl

use strict;
use warnings;

use Test::More;

use Cwd 'abs_path';
use File::Basename 'dirname';
use File::Spec ();
use FindBin '$Bin';

use File::ConfigDir ();

my $abs_bin     = abs_path($Bin);
my $bin_basedir = dirname($abs_bin);

my %common_base_tests = (
    '$a euals $b'        => [$abs_bin, $abs_bin],
    '$a shorter than $b' => [$abs_bin, File::Spec->catdir($abs_bin, "Foo")],
    '$b shorter than $a' => [File::Spec->catdir($abs_bin, "Foo"), $abs_bin],
);

foreach my $test (sort keys %common_base_tests)
{
    my $common_base_dir = File::ConfigDir::_find_common_base_dir(@{$common_base_tests{$test}});
    is($bin_basedir, $common_base_dir, $test);
}

done_testing;
