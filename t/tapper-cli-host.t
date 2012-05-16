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

my $retval;
my $host_id = `$^X -Ilib bin/tapper-testrun newhost  --name="host1"`;
chomp $host_id;

my $host_result = model('TestrunDB')->resultset('Host')->find($host_id);
ok($host_result->id, 'inserted host without option / id');
ok($host_result->free, 'inserted host  without option / free');
is($host_result->name, 'host1', 'inserted host without option / name');

# --------------------------------------------------

$host_id = `$^X -Ilib bin/tapper-testrun newhost  --name="host2" --active --queue=KVM`;
chomp $host_id;

$host_result = model('TestrunDB')->resultset('Host')->find($host_id);
ok($host_result->id, 'inserted host with active and existing queue / id');
is($host_result->name, 'host2', 'inserted host with active and existing queue / name');
ok($host_result->active, 'inserted host with active and existing queue / active');
ok($host_result->free, 'inserted host with active and existing queue / free');

# --------------------------------------------------

$host_id = `$^X -Ilib bin/tapper-testrun newhost  --name="host3" --queue=Xen --queue=KVM`;
chomp $host_id;

$host_result = model('TestrunDB')->resultset('Host')->find($host_id);
ok($host_result->id, 'inserted host with multiple existing queues / id');
is($host_result->name, 'host3', 'inserted host with multiple existing queues / name');
is($host_result->active, undef, 'inserted host with multiple existing queues / active');
ok($host_result->free, 'inserted host with multiple existing queues / free');
if ($host_result->queuehosts->count) {
        my @queue_names = map {$_->queue->name} $host_result->queuehosts->all;
        is_deeply(['Xen', 'KVM'] , \@queue_names, 'inserted host with multiple existing queues / queues');
}
else {
        fail("Queues assigned to host");
}

# --------------------------------------------------
$host_id = qx($^X -Ilib bin/tapper-testrun newhost  --name="host4" --queue=noexist 2>&1);
like($host_id, qr(No such queue: noexist), 'Error handling for nonexistent queue');


# --------------------------------------------------
my $hosts = qx($^X -Ilib bin/tapper-testrun listhost --queue=KVM 2>&1);
like($hosts, qr(11 *| *host2\n *12 *| *host3\n), 'Show hosts / queue');


# --------------------------------------------------
qx($^X -Ilib bin/tapper-testrun updatehost --delqueue --active --id=7 2>&1);
is($?, 0, 'Update host / return value');
$host_result = model('TestrunDB')->resultset('Host')->find(7);
ok($host_result->active, 'Update host / active');
is($host_result->queuehosts->count, 0, 'Update host / delete all queues');

# --------------------------------------------------
$retval = qx($^X -Ilib bin/tapper-testrun updatehost --active --name athene 2>&1);
diag($retval) if $?;
is($?, 0, 'Update host / return value');
$host_result = model('TestrunDB')->resultset('Host')->find(8);
ok($host_result->active, 'Update host by name/ active');

$retval = qx($^X -Ilib bin/tapper-testrun updatehost --noactive --name athene 2>&1);
diag($retval) if $?;
is($?, 0, 'Update host / return value');
$host_result = model('TestrunDB')->resultset('Host')->find(8);
ok(!$host_result->active, 'Update host by name/ deactivate');


# --------------------------------------------------
$host_result = model('TestrunDB')->resultset('Host')->find(7);
ok($host_result, 'Delete host / host exists before delete');
is($host_result->is_deleted, 0, 'Delete host / Deleted flag unset before delete');
is($host_result->active, 1, 'Delete host / Host active before delete');
is($host_result->name, 'dickstone', 'Working on the expected host');
qx($^X -Ilib bin/tapper-testrun deletehost --name=dickstone --really 2>&1);
$host_result = model('TestrunDB')->resultset('Host')->find(7);
isa_ok($host_result, 'Tapper::Schema::TestrunDB::Result::Host', 'Delete host / host still in DB');
is($host_result->is_deleted, 1, 'Delete host / Deleted flag set');
is($host_result->active, 0, 'Delete host / Host no longer active');






done_testing();
