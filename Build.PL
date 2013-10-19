use strict;
use warnings;

use Module::Build;

my $builder = Module::Build->new(
                              module_name       => 'File::ConfigDir',
                              license           => 'perl',
                              dist_author       => q{Jens Rehsack <rehsack@cpan.org>},
                              dist_version_from => 'lib/File/ConfigDir.pm',
                              build_requires    => {
                                                  'Test::More' => '0.90',
                                                },
                              recommends => {
                                              'File::HomeDir'   => '0.50',
                                              'List::MoreUtils' => '0.22',
                                            },
                              requires => {
                                            'Carp'           => 0,
                                            'File::Basename' => 0,
                                            'File::Spec'     => 0,
                                          },
                              add_to_cleanup => ['File-ConfigDir-*'],
                              meta_merge     => {
                                  resources => {
                                      repository => "https://github.com/perl5-utils/File-ConfigDir",
                                  },
                                  prereqs => {
                                               develop => {
                                                     requires => {
                                                         'Test::CPAN::Changes'                 => 0,
                                                         'Test::CheckManifest'                 => 0,
                                                         'Test::Pod'                           => 0,
                                                         'Test::Pod::Coverage'                 => 0,
                                                         'Test::Pod::Spelling::CommonMistakes' => 0,
                                                     },
                                                     recommends => {},
                                               },
                                             },
                                            },
                              test_files => join( ' ' => 't/*.t xt/*.t' ),
);

$builder->create_build_script();
