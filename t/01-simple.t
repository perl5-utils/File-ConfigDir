#!perl

use strict;
use warnings;

use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);

my $have_local_lib = eval "use local::lib '$dir'; 1;";

use Test::More;

use File::ConfigDir ':ALL';

my @supported_functions = (
    qw(config_dirs system_cfg_dir desktop_cfg_dir),
    qw(core_cfg_dir site_cfg_dir vendor_cfg_dir),
    qw(local_cfg_dir here_cfg_dir singleapp_cfg_dir vendorapp_cfg_dir),
    qw(xdg_config_dirs xdg_config_home user_cfg_dir locallib_cfg_dir),
);
foreach my $fn (@supported_functions)
{
    my $faddr;
    ok($faddr = File::ConfigDir->can($fn), "Can $fn");
    my @dirs = &{$faddr}();
    note("$fn: " . join(",", @dirs));
    if ($fn =~ m/(?:xdg_)?config_dirs/ or $fn =~ m/(?:machine|desktop)_cfg_dir/)
    {
        ok(scalar @dirs >= 1, $fn) or diag(join(",", @dirs));    # we expect at least system_cfg_dir
    }
    elsif ($fn eq "locallib_cfg_dir")
    {
        $have_local_lib and ok(scalar @dirs >= 1, $fn) or diag(join(",", @dirs));
        $have_local_lib or ok(0 == scalar @dirs, $fn) or diag(join(",", @dirs));
    }
    elsif ($fn =~ m/(?:local|user)_cfg_dir/ || $fn eq "xdg_config_home")
    {
        ok(scalar @dirs <= 1, $fn) or diag(join(",", @dirs));    # probably we do not have local::lib or File::HomeDir
    }
    elsif ($^O eq "MSWin32" and $fn eq "local_cfg_dir")
    {
        ok(scalar @dirs == 0, $fn) or diag(join(",", @dirs));
    }
    else
    {
        ok(scalar @dirs == 1, $fn) or diag(join(",", @dirs));
    }
}

done_testing();
