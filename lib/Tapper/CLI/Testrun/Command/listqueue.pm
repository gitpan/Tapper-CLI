package Tapper::CLI::Testrun::Command::listqueue;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';
use Tapper::Model 'model';


sub abstract {
        'List queues'
}

my $options = { "verbose"  => { text => "show all available information; without only show names", short => 'v' },
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
        if ($opt->{minprio} and $opt->{maxprio}) {
                $search{"-and"} = [ priority => {'>=' => $opt->{minprio}}, priority => {'<=' => $opt->{maxprio}}];
        } else {
                $search{priority} = {'>=' => $opt->{minprio}} if $opt->{minprio};
                $search{priority} = {'<=' => $opt->{maxprio}} if $opt->{maxprio};
        }

        if ($opt->{name}) {
                $search{"name"} = { '-in' => $opt->{name}};
                $opt->{verbose} = 1;
        }

        my $queues = model('TestrunDB')->resultset('Queue')->search(\%search, \%options);
        if ($opt->{verbose}) {
                $self->print_queues_verbose($queues)
        } else {
                foreach my $queue ($queues->all) {
                        say sprintf("%10d | %s", $queue->id, $queue->name);
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
                                     $queue->active ? 'yes' : 'no');
                if ($queue->queuehosts->count) {
                        my @hosts = map {$_->host->name} $queue->queuehosts->all;
                        $output  .= "Bound hosts: ";
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
