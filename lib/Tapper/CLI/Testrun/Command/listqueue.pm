package Tapper::CLI::Testrun::Command::listqueue;
BEGIN {
  $Tapper::CLI::Testrun::Command::listqueue::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::CLI::Testrun::Command::listqueue::VERSION = '4.1.3';
}

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';
use Tapper::Model 'model';


sub abstract {
        'List queues'
}

my $options = { "verbose"  => { text => "show all available information; without only show names", short => 'v' },
                "active"   => { text => "list active hosts", type => 'withno'},
                "all"      => { text => "list all hosts, even deleted ones"},
                "minprio"  => { text => "INT; queues with at least this priority level", type => 'string'},
                "maxprio"  => { text => "INT; queues with at most this priority level", type => 'string'},
                "name"     => { text => "show only queue with this name, implies verbose, can be given more than once", type => 'manystring' }
              };



sub opt_spec {
        my @opt_spec;
        foreach my $key (keys %$options) {
                my $pushkey = $key;
                $pushkey    = $pushkey."|".$options->{$key}->{short} if $options->{$key}->{short};

                given($options->{$key}->{type}){
                        when ("string")        {$pushkey .="=s";}
                        when ("withno")        {$pushkey .="!";}
                        when ("manystring")    {$pushkey .="=s@";}
                        when ("optmanystring") {$pushkey .=":s@";}
                        when ("keyvalue")      {$pushkey .="=s%";}
                }
                push @opt_spec, [$pushkey, $options->{$key}->{text}];
        }
        return (
                @opt_spec
               );
}


sub usage_desc {
        my $allowed_opts = join ' | ', map { '--'.$_ } _allowed_opts();
        "tapper-testrun listqueue " . $allowed_opts ;
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub _extract_bare_option_names {
        map { my $x = $_; $x =~ s/=.*//; $x } _allowed_opts();
}

sub validate_args {
        my ($self, $opt, $args) = @_;


        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        if (($args and @$args)) {
                say STDERR $msg, join(', ',@$args);
                die $self->usage->text;
        }
        if ($opt->{name} and ($opt->{minprio} or $opt->{maxprio})) {
                say STDERR "Search for either name or priority. Both together are not supported.";
                die $self->usage->text;
        }

        return 1;
}

sub execute {
        my ($self, $opt, $args) = @_;
        my %options= (order_by => 'name');
        my %search;
        $search{is_deleted} = {-in => [ 0, undef ] } unless $opt->{all};
        if ($opt->{minprio} and $opt->{maxprio}) {
                $search{"-and"} = [ priority => {'>=' => $opt->{minprio}}, priority => {'<=' => $opt->{maxprio}}];
        } else {
                $search{priority} = {'>=' => $opt->{minprio}} if $opt->{minprio};
                $search{priority} = {'<=' => $opt->{maxprio}} if $opt->{maxprio};
        }

        if ($opt->{name}) {
                # ignore all options if queue is requested by name
                %search = (name => { '-in' => $opt->{name}});
                $opt->{verbose} = 1;
        }

        my $queues = model('TestrunDB')->resultset('Queue')->search(\%search, \%options);
        if (defined($opt->{active})) {
                $queues = $queues->search({active => $opt->{active}});
        }
        if ($opt->{verbose}) {
                $self->print_queues_verbose($queues)
        } else {
                my $max_length=-1;

                foreach my $queue ($queues->all) {
                        $max_length = length $queue->name if length $queue->name > $max_length;
                }
                foreach my $queue ($queues->all) {
                        printf("%10d | ", $queue->id, $queue->name, $queue->priority);
                        print $queue->name, " "x($max_length - length($queue->name));
                        say " | ",$queue->priority;
                }
        }
}


sub print_queues_verbose
{
        my ($self, $queues) = @_;
        foreach my $queue ($queues->all) {
                my $output = sprintf("Id: %s\nName: %s\nPriority: %s\nActive: %s\n",
                                     $queue->id,
                                     $queue->name,
                                     $queue->priority,
                                     $queue->is_deleted ? 'deleted' : ( $queue->active ? 'yes' : 'no'));
                if ($queue->queuehosts->count) {
                        my @hosts = map {$_->host->name} $queue->queuehosts->all;
                        $output  .= "Bound hosts: ";
                        $output  .= join ", ",@hosts;
                        $output  .= "\n";
                }
                if ($queue->deniedhosts->count) {
                        my @hosts = map {$_->host->name} $queue->deniedhosts->all;
                        $output  .= "Denied hosts: ";
                        $output  .= join ", ",@hosts;
                        $output  .= "\n";
                }
                if ($queue->queued_testruns->count) {
                        my @ids   = map {$_->testrun_id} $queue->queued_testruns->all;
                        $output  .= "Queued testruns (ids): ";
                        $output  .= join ", ",@ids;
                        $output  .= "\n";
                }
                say $output;
                say "*"x80;
        }
}


1;

# perl -Ilib bin/tapper-testrun listqueue -v

__END__

=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::Testrun::Command::listqueue

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
