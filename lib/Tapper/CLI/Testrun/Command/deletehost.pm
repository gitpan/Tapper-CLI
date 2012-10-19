package Tapper::CLI::Testrun::Command::deletehost;
BEGIN {
  $Tapper::CLI::Testrun::Command::deletehost::AUTHORITY = 'cpan:AMD';
}
{
  $Tapper::CLI::Testrun::Command::deletehost::VERSION = '4.1.0';
}

use 5.010;
use strict;
use warnings;

use parent 'App::Cmd::Command';
use Tapper::Model 'model';

sub abstract {
        'Delete a host'
}

sub opt_spec {
        return (
                [ "verbose|v",  "some more informational output" ],
                [ "really",   "really execute the command"     ],
                [ "id=s@",    "delete particular host",    ],
                [ "name=s@",  "Select host to delete by name" ],
               );
}

sub usage_desc {
        my $allowed_opts = join ' | ', map { '--'.$_ } _allowed_opts();
        "tapper-testrun deletehost [ " . $allowed_opts ." ]";
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
        say STDERR $msg, join(', ',@$args) if ($args and @$args);

        my $allowed_opts_re = join '|', _extract_bare_option_names();
        die "Really? Then add --really to the options.\n" unless $opt->{really};

        return 1 if grep /$allowed_opts_re/, keys %$opt;
        die $self->usage->text;
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


sub execute {
        my ($self, $opt, $args) = @_;

 NAME:
        foreach my $name (@{$opt->{name}}) {
                my $host = model('TestrunDB')->resultset('Host')->search({name => $name}, {rows => 1})->first;
                push @{$opt->{id}}, $host->id;
        }

 ID:
        foreach my $id (@{$opt->{id}}){
                my $host = model('TestrunDB')->resultset('Host')->find($id);
                if (not $host) {
                        warn "No host with $id";
                        next ID;
                }
                my $name = $host->name;
                $self->update_grub($host);
                $host->active(0);
                $host->is_deleted(1);
                $host->update();
                say "Deleted host $name with id $id" if $opt->{verbose};
        }
}

1;

# perl -Ilib bin/tapper-testrun delete --id 16

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::Testrun::Command::deletehost

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

