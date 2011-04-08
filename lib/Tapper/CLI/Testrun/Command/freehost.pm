package Tapper::CLI::Testrun::Command::freehost;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';
use Tapper::Model 'model';



sub abstract {
        'Update an existing host'
}


my $options =  {
                "verbose"          => { text => "some more informational output", short=> 'v' },
                "name"             => { text => "TEXT; free host with this name",    type => 'string' },
                "desc"             => { text => "TEXT; describe why the host is freed",    type => 'string' },
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


sub validate_args
{
        my ($self, $opt, $args) = @_;

        if (($args and @$args)) {
                my $msg = "Unknown option";
                $msg   .= ($args and $#{$args} >=1) ? 's' : '';
                $msg   .= ": ";
                die $msg, join(', ',@$args), "\n";
        }

        if (not $opt->{name}) {
                die "Missing argument --name\n", $self->usage->text;
        }
        return 1;
}

=head2 free_host

Send message to MCP and tell it to cancel the currently running test on
given host. Requires the install config for this host on the same
machine.

@param host object - host to free
@param hash ref    - options

@return 0

@throws untyped exception

=cut

sub free_host
{
        my ($self, $opt) = @_;

        my $host = model('TestrunDB')->resultset('Host')->search(name => $opt->{name})->first;
        die "No such host: $opt->{name}" if not  $host;
        my $tr_sched = model('TestrunDB')->resultset('TestrunScheduling')->search({host_id => $host->id, status => 'running'})->first;
        return 0 if not $tr_sched;

        my $msg       = {state => 'quit'};
        $msg->{error} = $opt->{desc} if $opt->{desc};
        my $msg_rs    = model('TestrunDB')->resultset('Message')->new({testrun_id => $tr_sched->testrun->id, message => $msg});
        $msg_rs->insert;
        return 0;
}


sub execute 
{
        my ($self, $opt, $args) = @_;

        $self->free_host($opt);
        say "Host $opt->{name} is free now";
}


1;
