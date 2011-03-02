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


my $testplan_id = `/usr/bin/env perl -Ilib bin/tapper-testrun newtestplan --file t/files/testplan/osrc/athlon/kernel.mpc  -It/files/testplan/`;
chomp $testplan_id;
like($testplan_id, qr/^\d+$/, 'Testplan id is actually an id');

my $instance = model('TestrunDB')->resultset('TestplanInstance')->find($testplan_id);
ok($instance, 'Testplan instance found');
is(int $instance->testruns, 4, 'Testruns created from requested_hosts_all, requested_hosts_any, requested_hosts_any');

TODO: {
        local $TODO = 'searching all hosts with a given feature set is not yet implemented';
        is(int $instance->testruns, 6, 'Testruns created from all requests');
}

done_testing();
