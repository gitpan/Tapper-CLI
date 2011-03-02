package Tapper::CLI::Testrun::Command::newprecondition;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use File::Slurp qw/read_file/;

use Tapper::Cmd::Precondition;
use Tapper::Model 'model';


sub abstract {
        'Create a new precondition'
}

sub opt_spec {
        return (
                [ "verbose",          "some more informational output"                                            ],
                [ "timeout=s",        "INT; stop trying to fullfill this precondition after timeout second",      ],
                [ "condition=s",      "TEXT; condition description in YAML format (see Spec)"                     ],
                [ "condition_file=s", "STRING; filename from where to read condition, use - to read from STDIN"   ],
                [ "shortname=s",      "TEXT; shortname that overrides the one in the yaml"                        ],
                [ "precondition=s@",  "INT; assigned pre-precondition ids"                                        ],
               );
}

sub usage_desc
{
        "tapper-testrun newprecondition ( --condition=s | --condition_file=s ) [ --shortname=s ] [ --timeout=n ] [ --precondition=n ]* ";
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


        my $precond_ok = 1;
        if (not $opt->{condition} || $opt->{condition_file}) {
                say "Missing --condition or --condition_file";
                $precond_ok = 0;
        }
        if ($opt->{condition} && $opt->{condition_file}) {
                say "Only one of --condition or --condition_file allowed.";
                $precond_ok = 0;
        }

        return 1 if $precond_ok;
        die $self->usage->text;
}

sub execute 
{
        my ($self, $opt, $args) = @_;

        $self->new_precondition ($opt, $args);
}

sub read_condition_file
{
        my ($condition_file) = @_;

        my $condition;

        # read from file or STDIN if filename == '-'

        if ($condition_file) {
                if ($condition_file eq '-') {
                        $condition = read_file (\*STDIN);
                } else {
                        $condition = read_file ($condition_file);
                }
        }
        return $condition;
}

sub new_precondition
{
        my ($self, $opt, $args) = @_;

        my $condition                       = $opt->{condition};
        my $condition_file                  = $opt->{condition_file};
        my $timeout                         = $opt->{timeout};

        $condition ||= read_condition_file($condition_file);
        $condition .= "\n" unless $condition =~ /\n$/;

        my $cmd = Tapper::Cmd::Precondition->new();

        my @ids;
        @ids = $cmd->add($condition);


        foreach my $id (@ids) {
                my $precondition = model('TestrunDB')->resultset('Precondition')->search({id => $id})->first;
                print $opt->{verbose} ? $precondition->to_string : $id, "\n";

        }
}

# perl -Ilib bin/tapper-testrun newprecondition --condition_file=- --timeout=100

1;
