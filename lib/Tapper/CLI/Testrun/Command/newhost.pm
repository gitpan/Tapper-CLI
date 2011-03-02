package Tapper::CLI::Testrun::Command::newhost;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Tapper::Model 'model';


sub abstract {
        'Create a new host'
}


my $options =  {
                "verbose"          => { text => "some more informational output" },
                "name"             => { text => "TEXT; name",    type => 'string' },
                "active"           => { text => "INT; MCP can use this host, default 0", type => 'bool' },
                "queue"            => { text => "TEXT; Bind host to named queue (queue has to exists already)", type => 'manystring'}
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
        "tapper-testrun newhost --name=s [ --queue=s@ --active=s --verbose ]*";
}

sub validate_args
{
        my ($self, $opt, $args) = @_;

        say "Missing argument --name"     unless  $opt->{name};
        if ($opt->{queue}) {
                foreach my $queue(@{$opt->{queue}}) {
                        my $queue_rs = model('TestrunDB')->resultset('Queue')->search({name => $queue});
                        if (not $queue_rs->count) {
                                say STDERR "No such queue: $queue";
                                my @queue_names = map {$_->name} model('TestrunDB')->resultset('Queue')->all;
                                say STDERR "Existing queues: ",join ", ",@queue_names;
                                die $self->usage->text;
                        }
                }
        }

        return 1 if $opt->{name};
        die $self->usage->text;
}

sub new_host
{
        my ($self, $opt, $args) = @_;


        my $host = {
                    name   => $opt->{name},
                    active => $opt->{active},
                    free   => 1,
                   };
        
        my $newhost = model('TestrunDB')->resultset('Host')->new($host);
        $newhost->insert();
        die "Can't create new host" if not $newhost;

        if ($opt->{queue}) {
                foreach my $queue (@{$opt->{queue}}) {
                        my $queue_rs   = model('TestrunDB')->resultset('Queue')->search({name => $queue});
                        if (not $queue_rs->count) {
                                $newhost->delete();
                                say STDERR qq(Did not find queue "$queue");
                        }
                        my $queue_host = model('TestrunDB')->resultset('QueueHost')->new({
                                                                                          host_id  => $newhost->id,
                                                                                          queue_id => $queue_rs->first->id,
                                                                                         });
                        $queue_host->insert();
                }
        }

        say $newhost->id;
}

sub execute 
{
        my ($self, $opt, $args) = @_;

        $self->new_host ($opt, $args);
}


# perl -Ilib bin/tapper-testrun newqueue --name="xen-3.2" --priority=200

1;
