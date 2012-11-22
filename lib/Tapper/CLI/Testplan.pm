package Tapper::CLI::Testplan;
BEGIN {
  $Tapper::CLI::Testplan::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::CLI::Testplan::VERSION = '4.1.2';
}
# ABSTRACT: Handle testplans

use 5.010;
use warnings;
use strict;

# TODO: Should Tapper::Testplan::* better be in Tapper::Cmd::Testplan?
use Tapper::Testplan::Reporter;
use Tapper::Testplan::Generator;
use Tapper::Cmd::Testplan;
use Tapper::Model 'model';



sub testplansend
{
        my ($c) = @_;
        $c->getopt( 'name|n=s@','file|f=s@','quiet|q', 'help|?' );

        if ( $c->options->{help} ) {
                say STDERR "Usage: $0 testplan-send [ --name=path ]* [ --file=filename ]  [ --quiet ]";
                say STDERR "";
                say STDERR "    --name       Path name to request only this task to be reported.";
                say STDERR "                 Slash(/) or dot(.) are allowed as separators.";
                say STDERR "                 Can be given multiple times.";
                say STDERR "                 Can be combined with --file.";
                say STDERR "    --file       File containing tasknames to be reported, one per line.";
                say STDERR "                 Slash(/) or dot(.) are allowed as separators.";
                say STDERR "                 Can be given multiple times.";
                say STDERR "                 Can be combined with --name.";
                say STDERR "    --quiet      Stay silent when testplan was sent.";
                say STDERR "    --help       Print this help message and exit.";
                exit -1;
        }

        my @names;
        if ($c->options->{name}) {
                push @names, map { tr|.|/|; { path => $_ } } @{$c->options->{name}}; ## no critic
        }
        if ($c->options->{file}) {
                foreach my $file (@{$c->options->{file}}) {
                        open my $FILE, "<", $file or die "Cannot open $file";
                        my @tasknames = map { chomp ; $_ } <$FILE>;
                        close $FILE;
                        push @names, map { tr|.|/|; { path => $_ } } @tasknames; ## no critic
                }
        }

        my $reporter = Tapper::Testplan::Reporter->new();
        $reporter->run(@names);
        return "Sending testplan finished" unless $c->options->{quiet};
        return;
}


sub testplanlist
{
        my ($c) = @_;
        $c->getopt( 'name|n=s@','testrun|t=s@', 'active|a', 'quiet|q', 'help|?' );

        if ( $c->options->{help} ) {
                say STDERR "Usage: $0 testplan-list [ --name=path ]* [ --testrun=id ]*  [ --quiet ]";
                say STDERR "";
                say STDERR "    --name       Path name of testplans to list.";
                say STDERR "                 Only slashes(/) are allowed as separators.";
                say STDERR "                 Can be a regular expression. Make sure your shell does not break it.";
                say STDERR "                 Can be given multiple times";
                say STDERR "    --testrun    Show testplan containing this testrun id";
                say STDERR "                 Can be given multiple times";
                say STDERR "    --id         Show testplan of given id";
                say STDERR "                 Can be given multiple times.";
                say STDERR "    --active     Only show testplan with testruns that are not finished yet.";
                say STDERR "    --quiet      Only show testplan ids, suppress path, name and testrun ids.";
                say STDERR "    --help       Print this help message and exit.";
                exit -1;
        }
        my @ids;
        my @testplan_info;

        if (@{$c->options->{testrun} || []}) {
                my $testruns = model('TestrunDB')->resultset('Testrun')->search({id => $c->options->{testrun}});
                while (my $testrun = $testruns->next) {
                        push @ids, $testrun->testplan_id if $testrun->testplan_id;
                }
        } elsif ( @{$c->options->{name} || []}) {
                my $regex = join("|", map { "($_)" } @{$c->options->{name}});
                my $instances = model('TestrunDB')->resultset('TestplanInstance');
                while (my $instance = $instances->next) {
                        push @ids, $instance->id if $instance->path and $instance->path =~ /$regex/;
                }
        } else {
                my $instances = model('TestrunDB')->resultset('TestplanInstance');
                while (my $instance = $instances->next) {
                        push @ids, $instance->id;
                }
        }

        if ($c->options->{active}) {
                my @local_ids = @ids;
                my $instances = model('TestrunDB')->resultset('TestplanInstance')->search({id => \@local_ids});
                @ids = ();
                while (my $instance = $instances->next) {
                        if ($instance->testruns and grep {$_->testrun_scheduling->status ne 'finished'} $instance->testruns->all) {
                                push @ids, $instance->id;
                        }
                }
        }

        if ($c->options->{quiet}) {
                return join ("\n",@ids);
        }

        my $instances = model('TestrunDB')->resultset('TestplanInstance')->search({id => \@ids});
        while (my $instance = $instances->next) {
                my $line = $instance->id;
                $line   .= " - ";
                $line   .= ($instance->path ? $instance->path : '' )." - ";
                $line   .= "testruns: ";
                $line   .= join ", ", map {$_->id} $instance->testruns->all;
                push @testplan_info, $line;
        }
        return join "\n", @testplan_info;
}


sub testplan_tj_send
{
        my ($c) = @_;
        if ( $c->options->{help} ) {
                say STDERR "Usage: $0 testplan-tj-send";
                say STDERR "";
                say STDERR "    --help       Print this help message and exit.";
                exit -1;
        }

        my $reporter = Tapper::Testplan::Reporter->new();
        $reporter->run;
        return 0;
}



sub testplan_tj_generate
{
        my ($c) = @_;
        if ( $c->options->{help} ) {
                say STDERR "Usage: $0 testplan-tj-generate";
                say STDERR "";
                say STDERR "    --help       Print this help message and exit.";
                exit -1;
        }
        my $generator = Tapper::Testplan::Generator->new();
        $generator->run;
        return 0;
}


sub testplannew
{
        my ($c) = @_;
        $c->getopt( 'include|I=s@', 'name=s', 'path=s', 'file=s', 'D=s%', 'dryrun|n', 'guide|g', 'quiet|q', 'verbose|v', 'help|?' );

        my $opt = $c->options;

        if ( $opt->{help} or not $opt->{file}) {
                say STDERR "Usage: $0 testplan-new --file=s  [ -n ] [ -v ] [ -Dkey=value ] [ --path=s ] [ --name=s ] [ --include=s ]*";
                say STDERR "";
                say STDERR "    --verbose    Show more progress output.";
                say STDERR "    --quiet      Only show testplan ids, suppress path, name and testrun ids.";
                say STDERR "    --help       Print this help message and exit.";
                exit -1;
        }

        die "Testplan file needed\n" if not $opt->{file};
        die "Testplan file @{[ $opt->{file} ]} does not exist"  if not -e $opt->{file};
        die "Testplan file @{[ $opt->{file} ]} is not readable" if not -r $opt->{file};

        my $cmd = Tapper::Cmd::Testplan->new;
        $cmd->testplannew($opt);
        return;
}



sub setup
{
        my ($c) = @_;
        $c->register('testplan-send', \&testplansend, 'Send choosen testplan reports');
        $c->register('testplan-list', \&testplanlist, 'List testplans matching a given pattern');
        $c->register('testplan-tj-send', \&testplan_tj_send, 'Send all testplan reports that are due according to taskjuggler plan');
        $c->register('testplan-tj-generate', \&testplan_tj_generate, 'Apply all testplans that are due according to taskjuggler plan');
        $c->register('testplan-new', \&testplannew, 'Create new testplan instance from file');
        if ($c->can('group_commands')) {
                $c->group_commands('Testplan commands', 'testplan-send', 'testplan-list', 'testplan-tj-send', 'testplan-tj-generate');
        }
        return;
}

1; # End of Tapper::CLI

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::Testplan - Handle testplans

=head1 SYNOPSIS

This module is part of the Tapper::CLI framework. It is supposed to be
used together with App::Rad. All following functions expect their
arguments as $c->options->{$arg}.

    use App::Rad;
    use Tapper::CLI::Testplan;
    Tapper::CLI::Testplan::setup($c);
    App::Rad->run();

=head1 NAME

Tapper::CLI::Testplan - Tapper - testplan related commands for the tapper CLI

=head1 FUNCTIONS

=head2 testplansend

Send testplan reports to Taskjuggler. If optional names are given only tasks
that match at least one such name are reported.

@optparam name  - full subtask path (bot dot and slash are allowed as separatot)
@optparam quiet - stay silent when testplan was sent
@optparam help  - print out help message and die

=head2 testplanlist

List testplans matching a given pattern.

=head2 testplan_tj_send

Send all testplans reports choosen by Taskjuggler.

=head2 testplan_tj_generate

Apply all testplans choosen by Taskjuggler.

=head2 testplannew

Create new testplan instance from file.

=head2 setup

Initialize the testplan functions for tapper CLI

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

