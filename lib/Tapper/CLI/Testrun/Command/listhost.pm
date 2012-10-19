package Tapper::CLI::Testrun::Command::listhost;
BEGIN {
  $Tapper::CLI::Testrun::Command::listhost::AUTHORITY = 'cpan:AMD';
}
{
  $Tapper::CLI::Testrun::Command::listhost::VERSION = '4.1.0';
}

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Tapper::Model 'model';

sub abstract {
        'List hosts'
}

my $options = { "verbose"  => { text => "show all available information; without only show names", short => 'v' },
                "queue"    => { text => "list hosts bound to this queue", type=> 'manystring'},
                "all"      => { text => "list all hosts, even deleted ones"},
                "active"   => { text => "list only active hosts"},
                "free"     => { text => "list free hosts" },
                "name"     => { text => "find host by name, implies verbose", type => 'string'},
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
        "tapper-testrun listhost " . $allowed_opts ;
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

        $opt->{verbose} = 1 if $opt->{name};

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
        return 1;
}

sub execute {
        my ($self, $opt, $args) = @_;
        my %options= (order_by => 'name');
        my %search;
        $search{active}     = 1 if $opt->{active};
        $search{is_deleted} = {-in => [ 0, undef ] } unless $opt->{all};
        $search{free}   = 1 if $opt->{free};

        # ignore all options if host is requested by name
        %search = (name   => $opt->{name}) if $opt->{name};

        if ($opt->{queue}) {
                my @queue_ids       = map {$_->id} model('TestrunDB')->resultset('Queue')->search({name => {-in => [ @{$opt->{queue}} ]}});
                $search{queue_id}   = { -in => [ @queue_ids ]};
                $options{join}      = 'queuehosts';
                $options{'+select'} = 'queuehosts.queue_id';
                $options{'+as'}     = 'queue_id';
        }
        my $hosts = model('TestrunDB')->resultset('Host')->search(\%search, \%options);
        if ($opt->{verbose}) {
                $self->print_hosts_verbose($hosts)
        } else {
                foreach my $host ($hosts->all) {
                        say sprintf("%10d | %s", $host->id, $host->name);
                }
        }
}

sub host_feature_summary
{
        my ($host) = @_;

        return join(",",
                    map { $_->value }
                    sort { $a->entry cmp $b->entry }
                    grep { $_->entry =~ /^(key_word|socket_type|revision)$/ }
                    $host->features->all
                   );
}

sub print_hosts_verbose
{
        my ($self, $hosts) = @_;
        my %max = (
                   name    => 4,
                   features => 10,
                   comment => 7,
                   queue   => 0,
                  );
 HOST:
        foreach my $host ($hosts->all) {
                my $features = host_feature_summary($host);
                $max{name}    = length($host->name) if length($host->name) > $max{name};
                $max{features} = length($features) if length($features) > $max{features};
                $max{comment} = length($host->comment) if length($host->comment) > $max{comment};
                next HOST if not $host->queuehosts->count;
                foreach my $queuehost ($host->queuehosts->all) {
                        $max{queue} = length($queuehost->queue->name) if length($queuehost->queue->name) > $max{queue};
                }
        }
        my ($name_length, $feature_length, $comment_length, $queue_length) = ($max{name}, $max{features}, $max{comment}, $max{queue});

        # use printf to get the wanted field width
        printf ("%5s | %${name_length}s | %-${feature_length}s | %11s | %10s | %${comment_length}s | Queues\n", 'ID', 'Name', 'Features', 'Active', 'Testrun ID', 'Comment');
        say "="x(5+$name_length+$feature_length+11+length('Testrun ID')+$comment_length+length('Queues')+6*length(' | '));


        foreach my $host ($hosts->all) {
                my ($name_length, $feature_length, $queue_length) = ($max{name}, $max{features}, $max{queue});
                my $testrun_id = 'unknown id';
                if (not $host->free) {
                        my $job_rs = model('TestrunDB')->resultset('TestrunScheduling')->search({host_id => $host->id, status => 'running'});
                        $testrun_id = $job_rs->search({}, {rows => 1})->first->testrun_id if $job_rs->count;
                }
                my $features = host_feature_summary($host);
                my $output = sprintf("%5d | %${name_length}s | %-${feature_length}s | %11s | %10s | %${comment_length}s | ",
                                     $host->id,
                                     $host->name,
                                     $features,
                                     $host->is_deleted ? 'deleted' : ( $host->active ? 'active' : 'deactivated' ),
                                     $host->free   ? 'free'   : "$testrun_id",
                                     $host->comment,
                                    );
                if ($host->queuehosts->count) {
                        $output .= join ", ", map {$_->queue->name} $host->queuehosts->all;
                }
                say $output;
        }
}


1;

# perl -Ilib bin/tapper-testrun list --id 16

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::Testrun::Command::listhost

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

