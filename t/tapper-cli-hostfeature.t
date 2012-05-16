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
ok($host_result->id, 'inserted host');
ok($host_result->free, 'inserted host - free');
is($host_result->name, 'host1', 'inserted host - name');

# --------------------------------------------------

my $answer;
$answer = `$^X -Ilib bin/tapper-testrun updatehostfeature  --hostname="host1" --entry=mem --value=2048`;

my $feature_result = model('TestrunDB')->resultset('HostFeature')->search({entry => "mem"})->first;
ok($feature_result && $feature_result->id, 'inserted feature');
is($feature_result->host_id, $host_id, 'inserted feature - host_id');
is($feature_result->entry,   'mem',    'inserted feature - name');
is($feature_result->value,   2048,     'inserted feature - value');

# --------------------------------------------------

$answer = `$^X -Ilib bin/tapper-testrun updatehostfeature  --hostname="host1" --entry=mem --value=4096`;

$feature_result = model('TestrunDB')->resultset('HostFeature')->search({host_id => $host_id, entry => "mem"})->first;
ok($feature_result && $feature_result->id, 'updated feature');
is($feature_result->host_id, $host_id, 'updated feature - host_id');
is($feature_result->entry,   'mem',    'updated feature - name');
is($feature_result->value,   4096,     'updated feature - value');

# --------------------------------------------------

$answer = `$^X -Ilib bin/tapper-testrun updatehostfeature  --hostname="host1" --entry=mem`;

like ($answer, qr/--really/, "needs --really to delete");
diag $answer;

$feature_result = model('TestrunDB')->resultset('HostFeature')->search({host_id => $host_id, entry => "mem"})->first;
ok($feature_result && $feature_result->id, 'feature still exists');
is($feature_result->host_id, $host_id, 'feature still exists - host_id');
is($feature_result->entry,   'mem',    'feature still exists - name');
is($feature_result->value,   4096,     'feature still exists - value');

# --------------------------------------------------

$answer = `$^X -Ilib bin/tapper-testrun updatehostfeature  --hostname="host1" --entry=mem --really`;

unlike ($answer, qr/--really/, "No hint to use --really because we do.");
$feature_result = model('TestrunDB')->resultset('HostFeature')->search({host_id => $host_id, entry => "mem"})->first;
is($feature_result, undef, 'feature deleted');

done_testing();
