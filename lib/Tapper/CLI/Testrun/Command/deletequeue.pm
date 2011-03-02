package Tapper::CLI::Testrun::Command::deletequeue;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';
use Tapper::Model 'model';
use Tapper::Cmd::Queue;


sub abstract {
        'Delete an existing queue'
}


my $options =  {
                "verbose" => { text => "some more informational output", short => 'v'            },
                "really"  => { text => "really execute the command"                              },
                "name"    => { text => "TEXT; name of the queue to be changed", type => 'string' },
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

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}


sub usage_desc
{
        my $allowed_opts = join ' | ', map { '--'.$_ } _allowed_opts();
        "tapper-testrun deletequeue [ " . $allowed_opts ." ]";
}

sub validate_args
{
        my ($self, $opt, $args) = @_;

        die $self->usage->text unless %$opt ;
        
        die "Missing argument --name" unless  $opt->{name};
        die "Really? Then add --really to the options.\n" unless $opt->{really};

        return 1 if $opt->{name};

}

sub delete_queue
{
        my ($self, $opt, $args) = @_;

        my $queue = model('TestrunDB')->resultset('Queue')->search({name => $opt->{name}})->first;
        die "No such queue: ".$opt->{name} if not $queue;

        my $cmd = Tapper::Cmd::Queue->new();
        $cmd->del($queue->id);

        say "Deleted queue ".$queue->name;
}

sub execute 
{
        my ($self, $opt, $args) = @_;

        $self->delete_queue ($opt, $args);
}


# perl -Ilib bin/tapper-testrun deletequeue --name="xen-3.2"

1;
