package Tapper::CLI::Testrun::Command::deletehost;

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

sub execute {
        my ($self, $opt, $args) = @_;

 ID:
        foreach my $id (@{$opt->{id}}){
                my $host = model('TestrunDB')->resultset('Host')->find($id);
                next ID if not $host;
                my $name = $host->name;
                $host->delete();
                say "Deleted host $name with id $id" if $opt->{verbose};
        }
}

1;

# perl -Ilib bin/tapper-testrun delete --id 16
