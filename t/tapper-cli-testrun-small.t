#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Tapper::CLI::Testrun;
use Tapper::Schema::TestTools;
use Tapper::Model 'model';
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $retval = `$^X -Ilib bin/tapper-testrun list --id=3002`;
is($retval,
'
********************************************************************************

id: 3002
topic: old_topic
shortname: ccc2-kernel
state: schedule
queue: Kernel
requested hosts: iring
auto rerun: no
precondition_ids: 9, 10, 8, 5
', 'List testrun / by id');

$retval = `$^X -Ilib bin/tapper-testrun list --host=iring --schedule`;
is($retval, "3001\n3002\n", 'List testrun / by host, schedule');

done_testing();
