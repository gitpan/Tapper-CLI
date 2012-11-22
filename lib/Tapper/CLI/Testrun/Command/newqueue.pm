package Tapper::CLI::Testrun::Command::newqueue;
BEGIN {
  $Tapper::CLI::Testrun::Command::newqueue::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::CLI::Testrun::Command::newqueue::VERSION = '4.1.2';
}

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Tapper::Cmd::Queue;
use Tapper::Model 'model';


sub abstract {
        'Create a new queue'
}


my $options =  {
                "verbose"          => { text => "some more informational output" },
                "name"             => { text => "TEXT; name",    type => 'string' },
                "priority"         => { text => "INT; priority", type => 'string' },
                "active"           => { text => "set active flag to this value, prepend with no to unset", type => 'withno' },
                };

sub opt_spec {
        my @opt_spec;
        foreach my $key (keys %$options) {
                my $pushkey;
                given($options->{$key}->{type}){
                        when ("string")     {$pushkey = $key ."=s";}
                        when ("manystring") {$pushkey = $key ."=s@";}
                        when ("keyvalue")   {$pushkey = $key ."=s%";}
                        default             {$pushkey = $key; }
                }
                push @opt_spec, [$pushkey, $options->{$key}->{text}];
        }
        return (
                @opt_spec
               );
}


sub usage_desc
{
        "tapper-testrun newqueue --name=s --priority=s [ --verbose ]";
}

sub validate_args
{
        my ($self, $opt, $args) = @_;

        #         print "opt  = ", Dumper($opt);
        #         print "args = ", Dumper($args);

        say "Missing argument --name"     unless  $opt->{name};
        say "Missing argument --priority" unless  exists($opt->{priority});

        return 1 if $opt->{name} and $opt->{priority};

        die $self->usage->text;
}

sub new_queue
{
        my ($self, $opt, $args) = @_;

        #print "opt  = ", Dumper($opt);

        my $queue = {
                     name        => $opt->{name},
                     priority    => $opt->{priority},
                     active      => $opt->{active} // 0,
                    };
        my @ids;

        my $cmd = Tapper::Cmd::Queue->new();
        my $queue_id = $cmd->add($queue);
        die "Can't create new queue because of an unknown error" if not $queue_id;

        if ($opt->{verbose}) {
                my $entry = model('TestrunDB')->resultset('Queue')->search({id => $queue_id}, {rows => 1})->first;
                say $entry->to_string;
        } else {
                say $queue_id;
        }
}

sub execute
{
        my ($self, $opt, $args) = @_;

        $self->new_queue ($opt, $args);
}


# perl -Ilib bin/tapper-testrun newqueue --name="xen-3.2" --priority=200

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::Testrun::Command::newqueue

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

