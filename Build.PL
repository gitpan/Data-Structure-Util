#!/usr/bin/perl
use Module::Build;
# See perldoc Module::Build for details of how this works

Module::Build->new
    (
    module_name     => 'Data::Structure::Util',
    license         => 'perl',
    requires        => {
                        perl => '5.6.0',
                       },
    build_requires => {
                        Test::Pod    => 0,
                        Test::Simple => 0,
                        Test::More   => 0,
                        Clone        => 0,
                      },
      dynamic_config => 0,
      sign => 1,
    )->create_build_script;
