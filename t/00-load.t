use Test::More;

use Class::C3;
use MRO::Compat;

my @modules = (
               'Tapper::CLI',
               'Tapper::CLI::API',
               'Tapper::CLI::API::Command::download',
               'Tapper::CLI::API::Command::upload',
               'Tapper::CLI::DbDeploy',
               'Tapper::CLI::DbDeploy::Command::init',
               'Tapper::CLI::DbDeploy::Command::makeschemadiffs',
               'Tapper::CLI::DbDeploy::Command::saveschema',
               'Tapper::CLI::DbDeploy::Command::upgrade',
               'Tapper::CLI::Testrun',
               'Tapper::CLI::Testrun::Command::delete',
               'Tapper::CLI::Testrun::Command::deletehost',
               'Tapper::CLI::Testrun::Command::deleteprecondition',
               'Tapper::CLI::Testrun::Command::deletequeue',
               'Tapper::CLI::Testrun::Command::freehost',
               'Tapper::CLI::Testrun::Command::list',
               'Tapper::CLI::Testrun::Command::listhost',
               'Tapper::CLI::Testrun::Command::listprecondition',
               'Tapper::CLI::Testrun::Command::listqueue',
               'Tapper::CLI::Testrun::Command::new',
               'Tapper::CLI::Testrun::Command::newhost',
               'Tapper::CLI::Testrun::Command::newprecondition',
               'Tapper::CLI::Testrun::Command::newqueue',
               'Tapper::CLI::Testrun::Command::newscenario',
               'Tapper::CLI::Testrun::Command::newtestplan',
               'Tapper::CLI::Testrun::Command::rerun',
               'Tapper::CLI::Testrun::Command::show',
               'Tapper::CLI::Testrun::Command::updatehost',
               'Tapper::CLI::Testrun::Command::updateprecondition',
               'Tapper::CLI::Testrun::Command::updatequeue',
              );

plan tests => int @modules;

foreach my $module(@modules) {
        require_ok($module);
}
