package Tapper::CLI::DbDeploy::Command::init;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Tapper::CLI::DbDeploy;
use Data::Dumper;
use Tapper::Schema::TestrunDB;
use Tapper::Schema::ReportsDB;


sub opt_spec {
        return (
                [ "verbose", "some more informational output"       ],
                [ "db=s",    "STRING, one of: ReportsDB, TestrunDB" ],
               );
}

sub abstract {
        'Initialize a database from scratch. DANGEROUS! Think twice.'
}

sub usage_desc
{
        my ($self, $opt, $args) = @_;
        my $allowed_opts = join ' ', map { '--'.$_ } $self->_allowed_opts();
        "tapper-db-deploy init --db=DBNAME  [ --verbose ]";
}

sub _allowed_opts {
        my ($self, $opt, $args) = @_;
        my @allowed_opts = map { $_->[0] } $self->opt_spec();
}

sub validate_args {
        my ($self, $opt, $args) = @_;

        #         print "opt  = ", Dumper($opt);
        #         print "args = ", Dumper($args);

        my $ok = 1;
        if (not $opt->{db})
        {
                say "Missing argument --db\n";
                $ok = 0;
        }
        elsif (not $opt->{db} =~ /^ReportsDB|TestrunDB$/)
        {
                say "Wrong DB name '".$opt->{db}."' (must be ReportsDB or TestrunDB)";
                $ok = 0;
        }

        return $ok if $ok;
        die $self->usage->text;
}

sub insert_initial_values
{
        my ($schema, $db) = @_;

        if ($db eq 'TestrunDB')
        {
                # ---------- Topic ----------

                # official topics
                my %topic_description = %Tapper::Schema::TestrunDB::Result::Topic::topic_description;

                foreach my $topic_name(keys %topic_description) {
                        my $topic = $schema->resultset('Topic')->new
                            ({ name        => $topic_name,
                               description => $topic_description{$topic_name},
                             });
                        $topic->insert;
                }
                my $queue = $schema->resultset('Queue')->new
                  ({ name     => 'AdHoc',
                     priority => 1000,
                     active   => 1,
                   });
                $queue->insert;

        }
}

sub init_db
{
        my ($self, $db) = @_;

        my $dsn  = Tapper::Config->subconfig->{database}{$db}{dsn};
        my $user = Tapper::Config->subconfig->{database}{$db}{username};
        my $pw   = Tapper::Config->subconfig->{database}{$db}{password};

        # ----- really? -----
        print "dsn = $dsn\n";
        print "Really delete all existing content and initialize from scratch (y/N)? ";
        read STDIN, my $answer, 1;
        do { print "Quit.\n"; return } unless lc $answer eq 'y';

        # ----- delete sqlite file -----
        if ($dsn =~ /dbi:SQLite:dbname/) {
                my ($tmpfname) = $dsn =~ m,dbi:SQLite:dbname=([\w./]+),i;
                unlink $tmpfname;
        }

        my $schema;
        $schema = Tapper::Schema::TestrunDB->connect ($dsn, $user, $pw) if $db eq 'TestrunDB';
        $schema = Tapper::Schema::ReportsDB->connect ($dsn, $user, $pw) if $db eq 'ReportsDB';
        $schema->deploy({ add_drop_table => 1 }); # may fail, does not provide correct order to drop tables
        insert_initial_values($schema, $db);
}

sub run
{
        my ($self, $opt, $args) = @_;

        my $db  = $opt->{db};
        $self->init_db($db);
}


# perl -Ilib bin/tapper-db-deploy init --db=ReportsDB

1;
