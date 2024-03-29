#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Tapper::CLI::Testrun;
use Tapper::CLI::Testrun::Command::list;
use Tapper::Schema::TestTools;
use Tapper::Model 'model';
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------------------------------------


my $testplan_id = `$^X -Ilib bin/tapper testplan-new --file t/files/testplan/osrc/athlon/kernel.mpc  -It/files/testplan/`;
chomp $testplan_id;
like($testplan_id, qr/^\d+$/, 'Testplan id is actually an id');

my $instance = model('TestrunDB')->resultset('TestplanInstance')->find($testplan_id);
ok($instance, 'Testplan instance found');
is(int $instance->testruns, 4, 'Testruns created from requested_hosts_all, requested_hosts_any, requested_hosts_any');

TODO: {
        local $TODO = 'searching all hosts with a given feature set is not yet implemented';
        is(int $instance->testruns, 6, 'Testruns created from all requests');
}

### test --dryrun
my $output = `$^X -Ilib bin/tapper testplan-new -n --file t/files/testplan/osrc/athlon/kernel.mpc  -It/files/testplan/`;
like($output, qr/SELF-DOCUMENTATION.*ZOMTEC.*preconditions:/s, "dryrun");

### test --guide (self-documentation)
$output = `$^X -Ilib bin/tapper testplan-new -g --file t/files/testplan/osrc/athlon/kernel.mpc  -It/files/testplan/`;
like($output, qr/SELF-DOCUMENTATION.*ZOMTEC.*/ms, "self-documentation");
unlike($output, qr/preconditions:/ms, "self-documentation but no preconditions");
unlike($output, qr/NOT PART OF SELF-DOCS/ms, "self-documentation but no normal comments");
done_testing();
