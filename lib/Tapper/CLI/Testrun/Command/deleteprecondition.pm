package Tapper::CLI::Testrun::Command::deleteprecondition;
BEGIN {
  $Tapper::CLI::Testrun::Command::deleteprecondition::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::CLI::Testrun::Command::deleteprecondition::VERSION = '4.1.3';
}

use strict;
use warnings;

use 5.010;

use parent 'App::Cmd::Command';
use Tapper::Cmd::Precondition;


sub abstract {
        'Delete a precondition'
}

sub opt_spec {
        return (
                [ "verbose",  "some more informational output" ],
                [ "really",   "really execute the command"     ],
                [ "id=s@",    "delete particular precondition",  {required => 1}  ],
               );
}

sub usage_desc {
        my $allowed_opts = join ' | ', map { '--'.$_ } _allowed_opts();
        "tapper-testrun deleteprecondition [ " . $allowed_opts ." ]";
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
        if (not $opt->{really}) {
                say STDERR "Really? Then add --really to the options.";
                die $self->usage->text;
        }
        return 0;
}

sub execute {
        my ($self, $opt, $args) = @_;
        my $retval;

        my $cmd = Tapper::Cmd::Precondition->new();
        foreach my $id (@{$opt->{id}}){
                $retval = $cmd->del($id);
                if ($retval) {
                        say STDERR $retval;
                } else {
                        say "Precondition with $id deleted";
                }
        }

}

1;

# perl -Ilib bin/tapper-testrun deleteprecondition --id 16

__END__

=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::Testrun::Command::deleteprecondition

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
