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

my $precond_id = `$^X -Ilib bin/tapper-testrun newprecondition  --condition="precondition_type: image\nname: suse.tgz"`;
chomp $precond_id;

my $precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
ok($precond->id, 'inserted precond / id');
like($precond->precondition, qr"precondition_type: image", 'inserted precond / yaml');

# --------------------------------------------------

my $old_precond_id = $precond_id;
$precond_id = `$^X -Ilib bin/tapper-testrun updateprecondition --id=$old_precond_id --shortname="foobar-perl-5.11" --condition="precondition_type: file\nname: some_file"`;
chomp $precond_id;

$precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
is($precond->id, $old_precond_id, 'update precond / id');
is($precond->shortname, 'foobar-perl-5.11', 'update precond / shortname');
like($precond->precondition, qr'precondition_type: file', 'update precond / yaml');

my @retval = `$^X -Ilib bin/tapper-testrun listprecondition --all`;
chomp @retval;
is_deeply(\@retval, [5, 6, 7, 8, 9, 10, 11, 101, 102, 103], 'List preconditions / all, short');

my $retval = `$^X -Ilib bin/tapper-testrun listprecondition --id=5 -v`;
is($retval, "5 | temare_producer | ---\nprecondition_type: produce\nproducer: Temare\nsubject: KVM\nbitness: 64\n | NULL | \n", 'List preconditions / id, long');

@retval = `$^X -Ilib bin/tapper-testrun listprecondition --testrun=3002`;
chomp @retval;
is_deeply(\@retval, [5, 8], 'List preconditions / per testrun, short');

@retval = `$^X -Ilib bin/tapper-testrun updateprecondition  --shortname="foobar-perl-5.11" --condition="precondition_type: file\nname: some_file" 2>&1`;
chomp @retval;
is($retval[0], "Required option missing: id", 'Update precondition / id');

`$^X -Ilib bin/tapper-testrun deleteprecondition --id=$precond_id --really`;
$precond = model('TestrunDB')->resultset('Precondition')->find($precond_id);
is($precond, undef, "delete precond");



done_testing();
