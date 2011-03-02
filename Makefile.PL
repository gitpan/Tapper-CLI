use strict;
use warnings;

use inc::Module::Install;

name     'Tapper-CLI';
all_from 'lib/Tapper/CLI.pm';
author   'AMD OSRC Tapper Team <tapper@amd64.org>';
license  'freebsd';

build_requires 'Test::More';
build_requires 'Test::Perl::Critic';
build_requires 'Test::Fixture::DBIC::Schema';
build_requires 'DBIx::Class'     => '0.08112';
build_requires 'Tapper::Test'    => "3.000001";
build_requires 'SQL::Translator' => '0.11003';

author_requires 'Module::Install::WriteAll';

requires 'perl'                      => '5.010';
requires 'parent'                    => 0;
requires 'App::Cmd'                  => '0.301';
requires 'DBIx::Class::TimeStamp'    => 0;
requires 'File::Slurp'               => 0;
requires 'IO::Socket'                => 0;
requires 'Template'                  => 0;
requires 'Tapper::Model'             => "3.000001";
requires 'Tapper::Config'            => "3.000001";
requires 'Tapper::Schema'            => "3.000001";
requires 'Tapper::Cmd'               => "3.000001";
requires 'Data::Dumper'              => 0;
requires 'DateTime::Format::Natural' => 0;
requires 'YAML::Syck'                => 0;
requires 'Moose'                     => 0;
requires 'MooseX::LazyRequire'       => '0.06';
install_script glob('bin/*');
WriteAll;

