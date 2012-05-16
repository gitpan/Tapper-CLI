package Tapper::CLI::Testrun::Command::deletequeue;
BEGIN {
  $Tapper::CLI::Testrun::Command::deletequeue::AUTHORITY = 'cpan:AMD';
}
{
  $Tapper::CLI::Testrun::Command::deletequeue::VERSION = '4.0.1';
}

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

        # Prevent unknown options
        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        if (($args and @$args)) {
                say STDERR $msg, join(', ',@$args);
                die $self->usage->text;
        }


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

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::Testrun::Command::deletequeue

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

