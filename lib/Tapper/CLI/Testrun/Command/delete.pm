package Tapper::CLI::Testrun::Command::delete;

use strict;
use warnings;

use 5.010;

use parent 'App::Cmd::Command';
use Tapper::Cmd::Testrun;


sub abstract {
        'Delete a testrun'
}

sub opt_spec {
        return (
                [ "verbose",  "some more informational output" ],
                [ "really",   "really execute the command"     ],
                [ "id=s@",    "delete particular testruns",    ],
               );
}

sub usage_desc {
        my $allowed_opts = join ' | ', map { '--'.$_ } _allowed_opts();
        "tapper-testrun delete [ " . $allowed_opts ." ]";
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

        return 1 if grep /$allowed_opts_re/, keys %$opt;
        die $self->usage->text;
}

sub execute {
        my ($self, $opt, $args) = @_;

        my $cmd = Tapper::Cmd::Testrun->new();
        foreach my $id (@{$opt->{id}}){
                my $error = $cmd->del($id);
                if ($error) {
                        say STDERR "Can not delete testrun $id: $error";
                }
                say "Deleted testrun $id" if $opt->{verbose};
        }
}

1;

# perl -Ilib bin/tapper-testrun delete --id 16
