package Tapper::CLI::Testrun::Command::updatequeue;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Tapper::Cmd::Queue;
use Tapper::Model 'model';


sub abstract {
        'Update an existing queue'
}


my $options =  {
                "verbose"          => { text => "some more informational output", short => 'v' },
                "name"             => { text => "TEXT; name of the queue to be changed",    type => 'string' },
                "priority"         => { text => "INT; priority", type => 'string', short => 'p' },
                "active"           => { text => "set active flag to this value, prepend with no to unset", type => 'withno' },
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


sub usage_desc
{
        "tapper-testrun updatequeue --name=s --priority=s [ --verbose ]";
}

sub validate_args
{
        my ($self, $opt, $args) = @_;

        say "Missing argument --name"         unless  $opt->{name};
        say "Missing argument what to change" unless  exists($opt->{priority}) or exists($opt->{active});

        return 1 if $opt->{name} and (exists($opt->{priority}) or exists($opt->{active}));

        die $self->usage->text;
}

sub update_queue
{
        my ($self, $opt, $args) = @_;


        my $queue = model('TestrunDB')->resultset('Queue')->search({name => $opt->{name}})->first;
        
        my $cmd = Tapper::Cmd::Queue->new();
        my $new_opts = {};

        $new_opts->{priority} = $opt->{priority} if defined($opt->{priority});
        $new_opts->{active}   = $opt->{active}   if defined($opt->{active});

        my $queue_id = $cmd->update($queue->id, $new_opts);
        die "Can't create new queue because of an unknown error" if not $queue_id;

        if ($opt->{verbose}) {
                $queue = model('TestrunDB')->resultset('Queue')->find($queue_id);
                say join " | ", ($queue->name, $queue->priority, $queue->active ? 'active' : 'not active');
        } else {
                say $queue_id;
        }
}

sub execute 
{
        my ($self, $opt, $args) = @_;

        $self->update_queue ($opt, $args);
}


# perl -Ilib bin/tapper-testrun newqueue --name="xen-3.2" --priority=200

1;
