package Tapper::CLI::Testrun::Command::renamequeue;
BEGIN {
  $Tapper::CLI::Testrun::Command::renamequeue::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::CLI::Testrun::Command::renamequeue::VERSION = '4.1.3';
}

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';
use Tapper::Model 'model';
use Tapper::Cmd::Queue;


sub abstract {
        'Rename an existing queue'
}


my $options =  {
                "verbose" => { text => "some more informational output", short => 'v'            },
                "really"  => { text => "really execute the command"                              },
                "oldname" => { text => "TEXT; name of the queue to be changed", type => 'string' },
                "newname" => { text => "TEXT; new name of the queue", type => 'string' },
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
        "tapper-testrun renamequeue [ " . $allowed_opts ." ]";
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


        die "Missing argument --oldname" unless  $opt->{oldname};
        die "Missing argument --newname" unless  $opt->{newname};

        return 1 if $opt->{name};

}

sub execute
{
        my ($self, $opt, $args) = @_;
        my $queue = model('TestrunDB')->resultset('Queue')->search({name => $opt->{oldname}}, {rows => 1})->first;
        die "No such queue: ".$opt->{oldname} if not $queue;
        $queue->name($opt->{newname});
        $queue->update;

        say "$opt->{oldname} is now known as $opt->{newname}";

}


# perl -Ilib bin/tapper-testrun deletequeue --name="xen-3.2"

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::Testrun::Command::renamequeue

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
