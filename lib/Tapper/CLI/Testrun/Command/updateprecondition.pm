package Tapper::CLI::Testrun::Command::updateprecondition;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use File::Slurp qw/read_file/;
use YAML::Syck qw/Load Dump/;

use Tapper::Cmd::Precondition;
use Tapper::Model 'model';

sub abstract {
        'Update an existing precondition'
}

sub opt_spec {
        return (
                [ "verbose|v",                           "some more informational output"                                            ],
                [ "shortname=s",                       "TEXT; shortname", { required => 1 }                                        ],
                [ "timeout=s",                         "INT; stop trying to fullfill this precondition after timeout second",      ],
                [ "condition=s",                       "TEXT; condition description in YAML format (see Spec)"                     ],
                [ "condition_file=s",                  "STRING; filename from where to read condition, use - to read from STDIN"   ],
                [ "precondition=s@",                   "INT; assigned pre-precondition ids"                                        ],
                [ "id=s",                              "INT; the precondition id to change", {required => 1 }                      ],
               );
}

sub usage_desc
{
        "tapper-testrun updateprecondition --id=s [ --shortname=s | --condition=s | --condition_file=s ) ";
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub validate_args {
        my ($self, $opt, $args) = @_;

        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        say STDERR $msg, join(', ',@$args) if ($args and @$args);

        say "Only one of --condition or --condition_file allowed." if $opt->{condition} && $opt->{condition_file};

        return 1 if $opt->{id};
        die $self->usage->text;
}

sub execute {
        my ($self, $opt, $args) = @_;

        $self->update_precondition ($opt, $args);
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

sub update_precondition
{
        my ($self, $opt, $args) = @_;

        #print "opt  = ", Dumper($opt);

        my $id             = $opt->{id};
        my $condition      = $opt->{condition};
        my $condition_file = $opt->{condition_file};
        my $shortname      = $opt->{shortname};


        $condition ||= read_condition_file($condition_file);
        if ($shortname) {
                my $data = Load($condition);
                $data->{shortname} = $shortname;
                $condition = Dump($data);
        }


        my $cmd = Tapper::Cmd::Precondition->new();

        $id = $cmd->update($id, $condition);

        if ($opt->{verbose}) {

                my $precondition = model('TestrunDB')->resultset('Precondition')->search({id => $id})->first;
                say $precondition->to_string;
        }  else {
                say $id;
        }
}



# perl -Ilib bin/tapper-testrun updateprecondition --shortname=perl-5.10 --condition_file=- --timeout=100

1;
