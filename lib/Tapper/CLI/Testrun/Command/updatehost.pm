package Tapper::CLI::Testrun::Command::updatehost;
BEGIN {
  $Tapper::CLI::Testrun::Command::updatehost::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::CLI::Testrun::Command::updatehost::VERSION = '4.1.3';
}

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Tapper::Model 'model';
use Tapper::Config;


sub abstract {
        'Update an existing host'
}


my $options =  {
                "verbose"          => { text => "some more informational output", short=> 'v' },
                "id"               => { text => "INT; change host with this id; required", type => 'optstring'},
                "name"             => { text => "TEXT; update name",    type => 'string' },
                "active"           => { text => "set active flag to this value, prepend with no to unset", type => 'withno' },
                "comment"          => { text => "Set a new comment for the host", type => 'string'},
                "addqueue"         => { text => "TEXT; Bind host to named queue without deleting other bindings (queue has to exists already)", type => 'manystring'},
                "delqueue"         => { text => "TEXT; delete queue from this host's bindings, empty string means 'all bindings'", type => 'optmanystring'},
               };

sub opt_spec {
        my @opt_spec;
        foreach my $key (keys %$options) {
                my $pushkey = $key;
                $pushkey    = $pushkey."|".$options->{$key}->{short} if $options->{$key}->{short};

                given($options->{$key}->{type}){
                        when ("string")        {$pushkey .="=s";}
                        when ("optstring")     {$pushkey .=":s";}
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

        unless (($opt->{id} or $opt->{name})) {
                warn "Please specify which host to update using --id or --name";
                die $self->usage->text;
        }

        if (@$args and (grep {$_ eq '--active'} @$args)) { # allow --active, even though it's not official
                @$args = grep {$_ ne '--active'} @$args;
                $opt->{active} = 1;
        }

        # Prevent unknown options
        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        if (($args and @$args)) {
                say STDERR $msg, join(', ',@$args);
                die $self->usage->text;
        }

        if ($opt->{name} and not $opt->{id}) {
                my $host = model('TestrunDB')->resultset('Host')->search({name => $opt->{name}}, {rows => 1})->first;
                if (not  $host) {
                        warn "No such host: $opt->{name}";
                        die $self->usage->text;
                }
                $opt->{id} = $host->id;
        }


        my $host = model('TestrunDB')->resultset('Host')->find($opt->{id});
        if (not $host) {
                say STDERR "No host with id ",$opt->{id};
                die $self->usage->text;
        }

        if ($opt->{addqueue}) {
                foreach my $queue(@{$opt->{addqueue}}) {
                        my $queue_rs = model('TestrunDB')->resultset('Queue')->search({name => $queue});
                        if (not $queue_rs->count) {
                                say STDERR "No such queue: $queue";
                                my @queue_names = map {$_->name} model('TestrunDB')->resultset('Queue')->all;
                                say STDERR "Existing queues: ",join ", ",@queue_names;
                                die $self->usage->text;
                        }
                }
        }

        return 1;
}

sub add_queues
{
        my ($self, $host, $queues) = @_;
 QUEUE:
        foreach my $queue (@$queues) {
                my $queue_rs   = model('TestrunDB')->resultset('Queue')->search({name => $queue});
                if (not $queue_rs->count) {
                        warn qq(Did not find queue "$queue" - ignoring);
                        next QUEUE;
                }
                my $queue_host = model('TestrunDB')->resultset('QueueHost')->new({
                                                                                  host_id  => $host->id,
                                                                                  queue_id => $queue_rs->search({}, {rows => 1})->first->id,
                                                                                 });
                $queue_host->insert();
        }
}

sub del_queues
{
        my ($self, $host, $queues) = @_;
 QUEUE:
        foreach my $queue (@$queues) {
                if ($queue eq '') {
                        my @queue_hosts = model('TestrunDB')->resultset('QueueHost')->search({host_id => $host->id});
                        foreach my $queue_host (@queue_hosts) {
                                $queue_host->delete();
                        }
                        return;
                }
                my $queue = model('TestrunDB')->resultset('Queue')->search({name => $queue}, {rows => 1})->first;
                if (not $queue) {
                        warn "No such queue $queue - ignoring";
                        next QUEUE;
                }
                my @queue_hosts = model('TestrunDB')->resultset('QueueHost')->search({host_id => $host->id, queue_id => $queue->id});
                foreach my $queue_host (@queue_hosts) {
                        $queue_host->delete();
                }
        }
}


sub update_grub
{
        my ($self, $hostname) = @_;
        my $message = model('TestrunDB')->resultset('Message')->new({type => 'action',
                                                                     message => {action => 'updategrub',
                                                                                 host   => $hostname,
                                                                                }});
        $message->insert;
        return 0;
}

sub execute
{
        my ($self, $opt, $args) = @_;
        my $host;

        $host = model('TestrunDB')->resultset('Host')->find($opt->{id});
        die "No such host: $opt->{id}" if not  $host;

        if (defined($opt->{active})) {
                $host->active($opt->{active});
                $self->update_grub($host->name)
                  if $opt->{active} == 0;
        }

        $host->name($opt->{name}) if $opt->{name};
        $self->del_queues($host, $opt->{delqueue}) if $opt->{delqueue};
        $self->add_queues($host, $opt->{addqueue}) if $opt->{addqueue};
        $host->comment($opt->{comment}) if defined($opt->{comment});
        $host->update;

        my $output = sprintf("%s | %s | %s | %s",
                             $host->id,
                             $host->name,
                             $host->active ? 'active' : 'deactivated',
                             $host->free   ? 'free'   : 'in use');
        if ($host->queuehosts->count) {
                foreach my $queuehost ($host->queuehosts->all) {
                        $output.= sprintf(" | %s",$queuehost->queue->name);
                }
        }
        say $output;
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::Testrun::Command::updatehost

=head2 update_grub

Install a default grub config for host so that it does no longer try to
execute Tapper testruns.

@return success - 0
@return error   - die()

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
