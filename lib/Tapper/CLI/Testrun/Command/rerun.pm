package Tapper::CLI::Testrun::Command::rerun;
BEGIN {
  $Tapper::CLI::Testrun::Command::rerun::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::CLI::Testrun::Command::rerun::VERSION = '4.1.3';
}

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Tapper::Cmd::Testrun;
use Tapper::Model 'model';

sub abstract {
        'Rerun an existing testrun with the same preconditions.'
}


sub opt_spec {
        return (
                [ "verbose",            "some more informational output"                                                                 ],
                [ "notes=s",            "TEXT; notes"                                                                                    ],
                [ "testrun=s",          "INT, testrun to start again"                                                                    ],
               );
}

sub usage_desc
{
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "tapper-testrun rerun --testrun=s [ --notes=s ]?";
}

sub _allowed_opts
{
        my @allowed_opts = map { $_->[0] } opt_spec();
}


sub validate_args
{
        my ($self, $opt, $args) = @_;


        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        say STDERR $msg, join(', ',@$args) if ($args and @$args);

        unless ($opt->{testrun}) {
                say "Missing argument --testrun";
                die $self->usage->text;
        }
        return 1;
}

sub execute
{
        my ($self, $opt, $args) = @_;

        $self->new_runtest ($opt, $args);
}


sub new_runtest
{
        my ($self, $opt, $args) = @_;

        my $id  = $opt->{testrun};
        my $cmd = Tapper::Cmd::Testrun->new();
        my $retval = $cmd->rerun($id, $opt);
        die "Can't restart testrun $id" if not $retval;

        my $testrun = model('TestrunDB')->resultset('Testrun')->find( $retval );

        print $opt->{verbose} ? $testrun->to_string : $testrun->id, "\n";
}


# perl -Ilib bin/tapper-testrun rerun --testrun=1234

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::Testrun::Command::rerun

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
