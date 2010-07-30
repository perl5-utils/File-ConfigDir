package File::ConfigDir;

use warnings;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

use Carp qw(croak);
use Config;
use Exporter ();
require File::Basename;
require File::Spec;

=head1 NAME

File::ConfigDir - Get directories of configuration files

=cut

$VERSION = '0.003';
@ISA     = qw(Exporter);
@EXPORT  = ();
@EXPORT_OK = (
               qw(config_dirs system_cfg_dir desktop_cfg_dir),
	       qw(xdg_config_dirs machine_cfg_dir),
               qw(core_cfg_dir site_cfg_dir vendor_cfg_dir),
               qw(locallib_cfg_dir local_cfg_dir),
	       qw(here_cfg_dir singleapp_cfg_dir),
	       qw(xdg_config_home user_cfg_dir)
             );
%EXPORT_TAGS = ( ALL => [@EXPORT_OK], );

my $haveFileHomeDir = 0;
eval {
    require File::HomeDir;
    $haveFileHomeDir = 1;
};

if ( eval { require List::MoreUtils; } )
{
    List::MoreUtils->import("uniq");
}
else
{
    # from PP part of List::MoreUtils
    eval <<'EOP';
sub uniq(&@) {
    my %h;
    map { $h{$_}++ == 0 ? $_ : () } @_;
}
EOP
}

=head1 SYNOPSIS

    use File::ConfigDir ':ALL';

    my @cfgdirs = config_dirs();
    my @appcfgdirs = config_dirs('app');

    # install support
    my $site_cfg_dir = site_cfg_dir();
    my $vendor_cfg_dir = site_cfg_dir();

=head1 DESCRIPTION

This module is a helper for installing, reading and finding configuration
file locations. It's intended to work in every supported Perl5 environment
and will always try to Do The Right Thing(tm).

C<File::ConfigDir> is a module to help out when perl modules (especially
applications) need to read and store configuration files from more than
one location. Writing user configuration is easy thanks to
L<File::HomeDir>, but what when the system administrator needs to place
some global configuration or there will be system related configuration
(in C</etc> on UNIX(tm) or C<$ENV{windir}> on Windows(tm)) and some
network configuration in nfs mapped C</etc/p5-app> or
C<$ENV{ALLUSERSPROFILE} . "\\Application Data\\p5-app">, respectively.

C<File::ConfigDir> has no "do what I mean" mode - it's entirely up to the
user to pick the right directory for each particular application.

=head1 EXPORT

Every function listed below can be exported, either by name or using the
tag C<:ALL>.

=head1 SUBROUTINES/METHODS

All functions can take one optional argument as application specific
configuration directory. If given, it will be embedded at the right (tm)
place of the resulting path.

=cut

sub _find_common_base_dir
{
    my ( $dira, $dirb ) = @_;
    my ( $va, $da, undef ) = File::Spec->splitpath($dira);
    my ( $vb, $db, undef ) = File::Spec->splitpath($dirb);
    my @dirsa = File::Spec->splitdir($da);
    my @dirsb = File::Spec->splitdir($db);
    my @commondir;
    my $max = $#dirsa < $#dirsb ? $#dirsa : $#dirsb;
    for my $i ( 0 .. $max )
    {
        $dirsa[$i] eq $dirsb[$i] or last;
        push( @commondir, $dirsa[$i] );
    }

    return File::Spec->catdir( $va, @commondir );
}

=head2 system_cfg_dir

Returns the configuration directory where configuration files of the
operating system resides. For Unices this is C</etc>, for MSWin32 it's
the value of the environment variable C<%windir%>.

=cut

my $system_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;
    if ( $^O eq "MSWin32" )
    {
        push( @dirs, $ENV{windir} );
    }
    else
    {
        push( @dirs, File::Spec->catdir( "/etc", @cfg_base ) );
    }
    return @dirs;
};

sub system_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "system_cfg_dir(;\$), not system_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return &{$system_cfg_dir}(@cfg_base);
}

=head2 machine_cfg_dir

Alias for desktop_cfg_dir - depreciated.

=head2 xdg_config_dirs

Alias for desktop_cfg_dir

=head2 desktop_cfg_dir

Returns the configuration directory where configuration files of the
desktop applications resides. For Unices this is C</etc/xdg>, for MSWin32
it's the value of the environment variable C<%ALLUSERSPROFILE%>
concatenated with the basename of the environment variable C<%APPDATA%>.

=cut

my $desktop_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;
    if ( $^O eq "MSWin32" )
    {
        my $alluserprof = $ENV{ALLUSERSPROFILE};
        my $appdatabase = File::Basename::basename( $ENV{APPDATA} );
        push( @dirs, File::Spec->catdir( $alluserprof, $appdatabase, @cfg_base ) );
    }
    else
    {
	if( $ENV{XDG_CONFIG_DIRS} )
	{
	    @dirs = split( ":", $ENV{XDG_CONFIG_DIRS} );
	    @dirs = map { File::Spec->catdir( $_, @cfg_base ) } @dirs;
	}
	else
	{
	    push( @dirs, File::Spec->catdir( "/etc", "xdg", @cfg_base ) );
	}
    }
    return @dirs;
};

sub desktop_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "desktop_cfg_dir(;\$), not desktop_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return &{$desktop_cfg_dir}(@cfg_base);
}

sub machine_cfg_dir
{
    goto \&desktop_cfg_dir;
}

sub xdg_config_dirs
{
    goto \&desktop_cfg_dir;
}

=head2 core_cfg_dir

Returns the C<etc> directory below C<$Config{prefix}>.

=cut

my $core_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    push( @dirs, File::Spec->catdir( $Config{prefix}, "etc", @cfg_base ) );
    return @dirs;
};

sub core_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "core_cfg_dir(;\$), not core_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return &{$core_cfg_dir}(@cfg_base);
}

=head2 site_cfg_dir

Returns the C<etc> directory below C<$Config{sitelib_stem}> or the common
base directory of C<$Config{sitelib}> and C<$Config{sitebin}>.

=cut

my $site_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    if ( $Config{sitelib_stem} )
    {
        push( @dirs, File::Spec->catdir( $Config{sitelib_stem}, "etc", @cfg_base ) );
    }
    else
    {
        my $sitelib_stem = _find_common_base_dir( $Config{sitelib}, $Config{sitebin} );
        push( @dirs, File::Spec->catdir( $sitelib_stem, "etc", @cfg_base ) );
    }

    return @dirs;
};

sub site_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "site_cfg_dir(;\$), not site_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return &{$site_cfg_dir}(@cfg_base);
}

=head2 vendor_cfg_dir

Returns the C<etc> directory below C<$Config{vendorlib_stem}> or the common
base directory of C<$Config{vendorlib}> and C<$Config{vendorbin}>.

=cut

my $vendor_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    if ( $Config{vendorlib_stem} )
    {
        push( @dirs, File::Spec->catdir( $Config{vendorlib_stem}, "etc", @cfg_base ) );
    }
    else
    {
        my $vendorlib_stem = _find_common_base_dir( $Config{vendorlib}, $Config{vendorbin} );
        push( @dirs, File::Spec->catdir( $vendorlib_stem, "etc", @cfg_base ) );
    }

    return @dirs;
};

sub vendor_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "vendor_cfg_dir(;\$), not vendor_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return &{$vendor_cfg_dir}(@cfg_base);
}

=head2 singleapp_cfg_dir

=cut

my $singleapp_cfg_dir = sub {
    my @dirs;

    my $appbin = File::Basename::dirname( $0 );
    my $appdir = File::Basename::dirname( $appbin );
    push( @dirs, File::Spec->catdir( $appdir, "etc" ) );

    return @dirs;
};

sub singleapp_cfg_dir
{
    my @cfg_base = @_;
    0 == scalar(@cfg_base)
      or croak "singleapp_cfg_dir(), not singleapp_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return &{$singleapp_cfg_dir}();
}

=head2 local_cfg_dir

Returns the configuration directory for distribution independent, 3rd
party applications. While this directory doesn't exists for MSWin32,
there will be only the path C</usr/local/etc> for Unices.

=cut

my $local_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    unless ( $^O eq "MSWin32" )
    {
	push( @dirs, File::Spec->catdir( "/usr", "local", "etc", @cfg_base ) );
    }

    return @dirs;
};

sub local_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "local_cfg_dir(;\$), not local_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return &{$local_cfg_dir}(@cfg_base);
}

=head2 locallib_cfg_dir

Extracts the C<INSTALL_BASE> from C<$ENV{PERL_MM_OPT}> and returns the
C<etc> directory below it.

=cut

my $locallib_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    if ( $INC{'local/lib.pm'} && $ENV{PERL_MM_OPT} && $ENV{PERL_MM_OPT} =~ m/.*INSTALL_BASE=([^"']*)['"]?$/ )
    {
        ( my $cfgdir = $ENV{PERL_MM_OPT} ) =~ s/.*INSTALL_BASE=([^"']*)['"]?$/$1/;
        push( @dirs, File::Spec->catdir( $cfgdir, "etc", @cfg_base ) );
    }

    return @dirs;
};

sub locallib_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "locallib_cfg_dir(;\$), not locallib_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return &{$locallib_cfg_dir}(@cfg_base);
}

=head2 here_cfg_dir

Returns the path for the C<etc> directory below the current working directory.

=cut

my $here_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    push( @dirs, File::Spec->catdir( File::Spec->rel2abs( File::Spec->curdir() ), @cfg_base, "etc" ) );

    return @dirs;
};

sub here_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "here_cfg_dir(;\$), not here_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return &{$here_cfg_dir}(@cfg_base);
}

=head2 user_cfg_dir

Returns the users home folder using L<File::HomeDir>. Without
File::HomeDir, nothing is returned.

=cut

my $user_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    push( @dirs, File::Spec->catdir( File::HomeDir->my_home(), map { "." . $_ } @cfg_base ) )
      if ($haveFileHomeDir);

    return @dirs;
};

sub user_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "user_cfg_dir(;\$), not user_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return &{$user_cfg_dir}(@cfg_base);
}

=head2 xdg_config_home

Returns the user configuration directory for desktop applications.
If C<< $ENV{XDG_CONFIG_HOME} >> is not set, for MSWin32 the value
of C<< $ENV{APPDATA} >> is return and on Unices the C<.config> directory
in the users home folder. Without L<File::HomeDir>, on Unices the returned
list might be empty.

=cut

my $xdg_config_home = sub {
    my @cfg_base = @_;
    my @dirs;

    if( $ENV{XDG_CONFIG_HOME} )
    {
	@dirs = split( ":", $ENV{XDG_CONFIG_HOME} );
	@dirs = map { File::Spec->catdir( $_, @cfg_base ) } @dirs;
    }
    elsif ( $^O eq "MSWin32" )
    {
        push( @dirs, File::Spec->catdir( $ENV{APPDATA}, @cfg_base ) );
    }
    else
    {
	push( @dirs, File::Spec->catdir( File::HomeDir->my_home(), ".config", @cfg_base ) )
	  if ($haveFileHomeDir);
    }
};

sub xdg_config_home
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "xdg_config_home(;\$), not xdg_config_home(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return &{$xdg_config_home}(@cfg_base);
}

=head2 config_dirs

    @cfgdirs = config_dirs();
    @cfgdirs = config_dirs( 'appname' );

Tries to get all available configuration directories as described above.
Returns those who exists and are readable.

=cut

sub config_dirs
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "config_dirs(;\$), not config_dirs(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    my @dirs = ();

    push( @dirs,
          &{$system_cfg_dir}(@cfg_base), &{$desktop_cfg_dir}(@cfg_base), &{$local_cfg_dir}(@cfg_base), );

    if( 0 == scalar(@cfg_base) )
    {
	push( @dirs, &{$singleapp_cfg_dir}() );
    }

    push( @dirs,
          &{$core_cfg_dir}(@cfg_base), &{$site_cfg_dir}(@cfg_base),   &{$vendor_cfg_dir}(@cfg_base),  
          &{$here_cfg_dir}(@cfg_base), &{$user_cfg_dir}(@cfg_base), &{$xdg_config_home}(@cfg_base), );

    @dirs = grep { -d $_ && -r $_ } uniq(@dirs);

    return @dirs;
}

=head1 AUTHOR

Jens Rehsack, C<< <rehsack at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-file-configdir at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-ConfigDir>.
I will be notified, and then you'll automatically be notified of progress
on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::ConfigDir

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-ConfigDir>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-ConfigDir>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-ConfigDir>

=item * Search CPAN

L<http://search.cpan.org/dist/File-ConfigDir/>

=back

=head1 ACKNOWLEDGEMENTS

Thanks are sent out to Lars Dieckow for his suggestion to add support
for the Base Directory Specification of the Free Desktop Group. Matthew
S. Trout earns the credit to suggest C<singleapp_cfg_dir> and remind
about C</usr/local/etc>.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 SEE ALSO

L<File::HomeDir>, L<File::ShareDir>, L<File::BaseDir> (Unices only)

=cut

1;    # End of File::ConfigDir
