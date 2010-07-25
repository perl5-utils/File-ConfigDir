#!perl

use strict;
use warnings;

eval {
    require local::lib;
    #local::lib->import();
};

use Test::More;

use File::ConfigDir ':ALL';

my @supported_functions = (
                            qw(config_dirs system_cfg_dir machine_cfg_dir),
                            qw(core_cfg_dir site_cfg_dir vendor_cfg_dir),
                            qw(local_cfg_dir user_cfg_dir)
                          );
foreach my $fn (@supported_functions)
{
    my $faddr;
    ok( $faddr = File::ConfigDir->can($fn), "Can $fn" );
    my @dirs = &{$faddr}();
    if ( "config_dirs" eq $fn )
    {
        ok( scalar @dirs > 1, "config_dirs" );    # we expect at least system_cfg_dir and user_cfg_dir
    }
    elsif ( $fn =~ m/(?:local|user)_cfg_dir/ )
    {
        ok( scalar @dirs <= 1, $fn );    # probably we do not have local::lib or File::HomeDir
    }
    else
    {
        ok( scalar @dirs == 1, $fn );
    }
}

done_testing();
