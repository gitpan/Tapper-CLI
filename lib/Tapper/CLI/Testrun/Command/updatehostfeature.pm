package Tapper::CLI::Testrun::Command::updatehostfeature;
BEGIN {
  $Tapper::CLI::Testrun::Command::updatehostfeature::AUTHORITY = 'cpan:AMD';
}
{
  $Tapper::CLI::Testrun::Command::updatehostfeature::VERSION = '4.1.0';
}

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Tapper::Model 'model';


sub abstract {
        'Create a new host'
}


my $options =  {
                "verbose"         => { text => "some more informational output", short => "v" },
                "really"          => { text => "really delete if no value given"       },
                "hostname"        => { text => "TEXT; hostname",      type => 'string' },
                "entry"           => { text => "TEXT; feature name",  type => 'string' },
                "value"           => { text => "TEXT; feature value", type => 'string' },
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
        "tapper-testrun updatehostfeature --hostname=s --entry=s --value=s [ --verbose ] [ --really ]";
}

sub validate_args
{
        my ($self, $opt, $args) = @_;

        say "Missing argument --hostname" unless  $opt->{hostname};
        say "Missing argument --entry"    unless  $opt->{entry};

        return 1 if ($opt->{hostname} and $opt->{entry});
        die $self->usage->text;
}

sub update_hostfeature
{
        my ($self, $opt, $args) = @_;

        my $hostname = $opt->{hostname};
        my $host     = model('TestrunDB')->resultset('Host')->search({name => $hostname}, {rows => 1})->first;

        if (not $host) {
                say STDERR "No such host: $hostname";
                die $self->usage->text;
        }

        my $hostfeature;

        $hostfeature = model('TestrunDB')->resultset('HostFeature')->search({ host_id => $host->id,
                                                                              entry   => $opt->{entry}},
                                                                            {rows => 1}
                                                                           )->first;
        if ($hostfeature and $hostfeature->id) {
                if (defined $opt->{value}) {
                        $hostfeature->value($opt->{value});
                        $hostfeature->update;
                        say sprintf("Updated feature for host '%s': %s = %s", $hostname, $hostfeature->entry, $hostfeature->value);
                } else {
                        if ($opt->{really}) {
                                $hostfeature->delete;
                                say sprintf("Deleted feature for host '%s': %s = %s", $hostname, $hostfeature->entry, $hostfeature->value);
                        } else {
                                say sprintf("Use --really to delete feature for host '%s': %s = %s", $hostname, $hostfeature->entry, $hostfeature->value);
                        }
                }
        } else {
                $hostfeature = model('TestrunDB')->resultset('HostFeature')->new({ host_id => $host->id,
                                                                                   entry   => $opt->{entry},
                                                                                   value   => $opt->{value},
                                                                                 });
                $hostfeature->insert;
                die "Can't create new hostfeature" if not $hostfeature;
                say sprintf("Created feature for host '%s': %s = %s", $hostname, $hostfeature->entry, $hostfeature->value);
        }
}

sub execute
{
        my ($self, $opt, $args) = @_;

        $self->update_hostfeature ($opt, $args);
}


# perl -Ilib bin/tapper-testrun updatehostfeature --hostname="grizzly" --entry="mem" --value="2048"

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::Testrun::Command::updatehostfeature

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

