package Tapper::CLI::Testrun::Command::show;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Tapper::Model 'model';

sub abstract {
        'Show details of a testrun'
}

sub opt_spec {
        return (
                [ "verbose",  "some more informational output" ],
                [ "id=s@",    "list particular testruns",      ],
               );
}

sub usage_desc {
        my $allowed_opts = join ' | ', map { '--'.$_ } _allowed_opts();
        "tapper-testrun show [ " . $allowed_opts ." ]";
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub _extract_bare_option_names {
        map { my $x = $_; $x =~ s/=.*//; $x } _allowed_opts();
}

sub validate_args {
        my ($self, $opt, $args) = @_;

#         print "opt  = ", Dumper($opt);
#         print "args = ", Dumper($args);

        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        say STDERR $msg, join(', ',@$args) if ($args and @$args);
        
        my $allowed_opts_re = join '|', _extract_bare_option_names();

        return 1 if grep /$allowed_opts_re/, keys %$opt;
        die $self->usage->text;
}

sub execute {
        my ($self, $opt, $args) = @_;

        $self->$_ ($opt, $args) foreach grep /^id$/, keys %$opt;
}

sub print_colnames
{
        my ($self, $opt, $args) = @_;

        return unless $opt->{colnames};

        my $columns = model('TestrunDB')->resultset('Testrun')->result_source->{_ordered_columns};
        print join( $Tapper::Schema::TestrunDB::DELIM, @$columns, '' ), "\n";
}

sub all
{
        my ($self, $opt, $args) = @_;

        print "All testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->all_testruns;#->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub queued
{
        my ($self, $opt, $args) = @_;

        print "Queued testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->queued_testruns;#->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub running
{
        my ($self, $opt, $args) = @_;

        print "Running testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->running_testruns;#->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub finished
{
        my ($self, $opt, $args) = @_;

        print "Finished testruns:\n" if $opt->{verbose};
        $self->print_colnames($opt, $args);

        my $testruns = model('TestrunDB')->resultset('Testrun')->finished_testruns;# ->search({}, { order_by => 'id' });
        while (my $testrun = $testruns->next) {
                print $testrun->to_string."\n";
        }
}

sub id
{
        my ($self, $opt, $args) = @_;

        my @ids = @{ $opt->{id} };

        $self->print_colnames($opt, $args);
        print _get_entry_by_id($_)->to_string."\n" foreach @ids;
}

# --------------------------------------------------

sub _get_entry_by_id {
        my ($id) = @_;
        model('TestrunDB')->resultset('Testrun')->find($id);
}

1;

# perl -Ilib bin/tapper-testrun list --id 16
