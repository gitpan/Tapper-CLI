#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Tapper::Schema::TestTools;
use Test::Fixture::DBIC::Schema;

# -----------------------------------------------------------------------------------------------------------------
construct_fixture( schema  => reportsdb_schema, fixture => 't/fixtures/reportsdb/report.yml' );
# -----------------------------------------------------------------------------------------------------------------




my $id = `$^X -Ilib bin/tapper notification-new --file=t/files/notification.yml -q`;
chomp $id;
like($id, qr"^\d+$", 'New notification substitution registered');

BAIL_OUT("Subscription id is used for further tests so we can not continue without this id") if not $id =~ m/^\d+$/;

my $list = `$^X -Ilib bin/tapper notification-list`;
is($list, q{---
comment: Testrun id 42 finished
event: testrun_finished
filter: testrun('id') == 42
id: 1
persist: 1
user_id: 1
},'List of notifications after notificationnew');

$id = `$^X -Ilib bin/tapper notification-update --file=t/files/notification_updated.yml --id=$id -q`;
chomp $id;
like($id, qr"^\d+$", 'New notification substitution registered');

$list = `$^X -Ilib bin/tapper notification-list`;
is($list, q{---
comment: Testrun id 43 finished
event: testrun_finished
filter: testrun('id') == 43
id: 1
persist: 1
user_id: 1
},'List of notifications after notificationupdate');


`$^X -Ilib bin/tapper notification-del --id=$id`;
$list = `$^X -Ilib bin/tapper notification-list`;
is($list, '','List of notifications after notificationdel');


done_testing();
