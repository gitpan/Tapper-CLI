
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Tapper - tapper-* commandline tools",
  "AUTHOR" => "AMD OSRC Tapper Team <tapper\@amd64.org>",
  "BUILD_REQUIRES" => {
    "Class::C3" => 0,
    "MRO::Compat" => 0,
    "Tapper::Schema::TestTools" => 0,
    "Test::Deep" => 0,
    "Test::Fixture::DBIC::Schema" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Tapper-CLI",
  "EXE_FILES" => [
    "bin/tapper-api",
    "bin/tapper-db-deploy",
    "bin/tapper",
    "bin/tapper-testrun"
  ],
  "LICENSE" => "open_source",
  "NAME" => "Tapper::CLI",
  "PREREQ_PM" => {
    "App::Cmd" => 0,
    "App::Cmd::Command" => 0,
    "App::Rad" => 0,
    "Compress::Bzip2" => 0,
    "Cwd" => 0,
    "Data::Dumper" => 0,
    "DateTime::Format::Natural" => 0,
    "File::ShareDir" => 0,
    "File::Slurp" => 0,
    "IO::Socket" => 0,
    "Moose" => 0,
    "Tapper::Cmd::Notification" => 0,
    "Tapper::Cmd::Precondition" => 0,
    "Tapper::Cmd::Queue" => 0,
    "Tapper::Cmd::Requested" => 0,
    "Tapper::Cmd::Scenario" => 0,
    "Tapper::Cmd::Testplan" => 0,
    "Tapper::Cmd::Testrun" => 0,
    "Tapper::Cmd::User" => 0,
    "Tapper::Config" => 0,
    "Tapper::Model" => 0,
    "Tapper::Reports::DPath::TT" => 0,
    "Tapper::Schema" => 0,
    "Tapper::Schema::ReportsDB" => 0,
    "Tapper::Schema::TestrunDB" => 0,
    "Tapper::Testplan::Reporter" => 0,
    "Template" => 0,
    "Try::Tiny" => 0,
    "UNIVERSAL" => 0,
    "YAML::Syck" => 0,
    "YAML::XS" => 0,
    "parent" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "4.0.1",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



