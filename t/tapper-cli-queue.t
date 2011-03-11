#! /usr/bin/env perl

use strict;
use warnings;

use Test::Deep;
use Test::More;
use Tapper::CLI::Testrun;
use Tapper::Schema::TestTools;
use Tapper::Model 'model';
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => testrundb_schema, fixture => 't/fixtures/testrundb/testruns_with_scheduling.yml' );
# -----------------------------------------------------------------------------------------------------------------

my $queue_id = `$^X -Ilib bin/tapper-testrun newqueue  --name="Affe" --priority=4711`;
chomp $queue_id;

my $queue = model('TestrunDB')->resultset('Queue')->find($queue_id);
ok($queue->id, 'inserted queue / id');
is($queue->name, "Affe", 'inserted queue / name');
is($queue->priority, 4711, 'inserted queue / priority');

`$^X -Ilib bin/tapper-testrun newhost  --name="host3" --queue=Xen --queue=KVM`;
is($?, 0, 'New host / return value');

my $retval = `$^X -Ilib bin/tapper-testrun listqueue --maxprio=300 --minprio=200 -v `;
is ($retval, "Id: 2\nName: KVM\nPriority: 200\nActive: no\nBound hosts: host3\n
********************************************************************************
Id: 1\nName: Xen\nPriority: 300\nActive: no\nBound hosts: host3\n
********************************************************************************
", 'List queues');
$retval = `$^X -Ilib bin/tapper-testrun listqueue --maxprio=10 -v `;
is($retval, "Id: 3\nName: Kernel\nPriority: 10\nActive: no\nQueued testruns (ids): 3001, 3002\n
********************************************************************************
", 'Queued testruns in listqueue');

$retval = `$^X -Ilib bin/tapper-testrun listqueue --name=Xen --name=Kernel`;
is($retval, 'Id: 3
Name: Kernel
Priority: 10
Active: no
Queued testruns (ids): 3001, 3002

********************************************************************************
Id: 1
Name: Xen
Priority: 300
Active: no
Bound hosts: host3

********************************************************************************
', 'List queues by name');


$retval = `$^X -Ilib bin/tapper-testrun updatequeue --name=Xen -p500 -v`;
is($retval, "Xen | 500 | not active\n", 'Update queue priority');

$retval = `$^X -Ilib bin/tapper-testrun updatequeue --name=Xen --active -v`;
is($retval, "Xen | 500 | active\n", 'Update queue active flag');

$retval = `$^X -Ilib bin/tapper-testrun updatequeue --name=Xen --noactive -v`;
is($retval, "Xen | 500 | not active\n", 'Update queue active flag');


$retval = `$^X -Ilib bin/tapper-testrun deletequeue --name=Xen --really`;
is($retval, "Deleted queue Xen\n", 'Delete queue');


done_testing();
