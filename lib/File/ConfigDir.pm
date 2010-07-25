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

$VERSION     = '0.001';
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(config_dirs system_cfg_dir machine_cfg_dir core_cfg_dir site_cfg_dir vendor_cfg_dir local_cfg_dir user_cfg_dir);
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

Quick summary of what the module does.

Perhaps a little code snippet.

    use File::ConfigDir;

    my $foo = File::ConfigDir->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=cut

sub _find_common_base_dir
{
    my ($dira, $dirb) = @_;
    while( $dira ne $dirb )
    {
        (undef, $dira) = File::Basename::fileparse($dira);
        (undef, $dirb) = File::Basename::fileparse($dirb);
    }

    return $dira;
}

=head2 system_cfg_dir

=cut

my $system_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;
    if ( $^O eq "MSWin32" )
    {
        push( @dirs, $ENV{windir} );
        # XXX All Users\\Application Data\\ ...
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

=cut

my $machine_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;
    if ( $^O eq "MSWin32" )
    {
        # ALLUSERSPROFILE
        my $alluserprof = $ENV{ALLUSERSPROFILE};
        my $appdatabase = File::Basename::basename($ENV{APPDATA});
        push( @dirs, File::Spec->catdir($alluserprof, $appdatabase, @cfg_base ) );
        # XXX All Users\\Application Data\\ ...
    }
    else
    {
        push( @dirs, File::Spec->catdir( "/etc", @cfg_base ) );
    }
    return @dirs;
};

sub machine_cfg_dir
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "machine_cfg_dir(;\$), not machine_cfg_dir(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    return &{$machine_cfg_dir}(@cfg_base);
}

=head2 core_cfg_dir

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

=cut

my $site_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    if( $Config{sitelib_stem} )
    {
        push( @dirs, File::Spec->catdir( $Config{sitelib_stem}, "etc", @cfg_base ) );
    }
    else
    {
        my $sitelib_stem = _find_common_base_dir($Config{sitelib}, $Config{sitebin});
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

=cut

my $vendor_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    if( $Config{sitelib_stem} )
    {
        push( @dirs, File::Spec->catdir( $Config{vendorlib_stem}, "etc", @cfg_base ) );
    }
    else
    {
        my $vendorlib_stem = _find_common_base_dir($Config{vendorlib}, $Config{vendorbin});
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

=head2 local_cfg_dir

=cut

my $local_cfg_dir = sub {
    my @cfg_base = @_;
    my @dirs;

    if ( $INC{'local/lib.pm'} )
    {
        ( my $cfgdir = $ENV{PERL_MM_OPT} ) =~ s/.*INSTALL_BASE=([^"']*)['"]?$/$1/;
        push( @dirs, File::Spec->catdir( $cfgdir, "etc", @cfg_base ) );
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

=head2 user_cfg_dir

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

=head2 config_dirs

    @cfgdirs = config_dirs();
    @cfgdirs = config_dirs( 'appname' );

=cut

sub config_dirs
{
    my @cfg_base = @_;
    1 < scalar(@cfg_base)
      and croak "config_dirs(;\$), not config_dirs(" . join( ",", ("\$") x scalar(@cfg_base) ) . ")";
    my @dirs = ();

    push( @dirs,
          &{$system_cfg_dir}(@cfg_base), &{$machine_cfg_dir}(@cfg_base), &{$core_cfg_dir}(@cfg_base),
          &{$site_cfg_dir}(@cfg_base),   &{$vendor_cfg_dir}(@cfg_base),  &{$local_cfg_dir}(@cfg_base),
          &{$user_cfg_dir}(@cfg_base), );

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

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Jens Rehsack.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;    # End of File::ConfigDir
