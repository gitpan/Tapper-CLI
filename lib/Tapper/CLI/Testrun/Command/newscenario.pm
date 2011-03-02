package Tapper::CLI::Testrun::Command::newscenario;

use 5.010;

use strict;
use warnings;
no warnings 'uninitialized';

use parent 'App::Cmd::Command';

use Tapper::Cmd::Scenario;
use Tapper::Cmd::Testrun;
use Tapper::Cmd::Precondition;
use Tapper::Cmd::Requested;


sub abstract {
        'Create a new scenario';
}


my $options = { "verbose" => { text => "some more informational output" },
                "quiet"   => { text => "only show scenario id, not testrun ids"},
                "D"       => { text => "Define a key=value pair used in macro preconditions", type => 'keyvalue' },
                "file"    => { text => "String; use macro scenario file", type => 'string' },
                };

sub opt_spec {
        my @opt_spec;
        foreach my $key (keys %$options) {
                my $pushkey;
                given($options->{$key}->{type}){
                        when ("string")     {$pushkey = $key ."=s";}
                        when ("manystring") {$pushkey = $key ."=s@";}
                        when ("keyvalue")   {$pushkey = $key ."=s%";}
                        default             {$pushkey = $key; }
                }
                push @opt_spec, [$pushkey, $options->{$key}->{text}];
        }
        return (
                @opt_spec
               );
}


sub usage_desc
{
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "tapper-testrun newscenario --file=s";
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
        if (($args and @$args)) {
                say STDERR $msg, join(', ',@$args);
                die $self->usage->text;
        }

        die "Scenario file needed\n",$self->usage->text if not $opt->{file};
        die "Scenario file ",$opt->{file}," does not exist" if not -e $opt->{file};
        die "Scenario file ",$opt->{file}," is not readable" if not -r $opt->{file};

        return 1;
}

=head2 execute

Worker function

=cut

sub execute
{
        my ($self, $opt, $args) = @_;

        use File::Slurp 'slurp';
        my $scenario = slurp($opt->{file});
        $scenario = $self->apply_macro($scenario, $opt->{d});

        use YAML::Syck 'Load';
        my $scenario_conf = Load($scenario);
        given ($scenario_conf->{scenario_type}) {
                when ('interdep') {
                        $self->parse_interdep($scenario_conf->{description}, $opt);
                }
                default {
                        die "Unknown scenario type ", $scenario_conf->{scenario_type};
                }
        };

        return 0;
}

=head2 apply_macro

Process macros and substit using Template::Toolkit.

@param hashref - hash containing options
@param hashref - hash containing arguments

@return success - yaml text with applied macros
@return error   - die with error string

=cut

sub apply_macro
{
        my ($self, $macro, $substitutes) = @_;

        use Template;
        my $tt            = new Template();
        my $ttapplied;

        $tt->process(\$macro, $substitutes, \$ttapplied) || die $tt->error();
        return $ttapplied;
}


sub add_host
{
        my ($self, $testrun_id, $host) = @_;
        my $cmd =  Tapper::Cmd::Requested->new();
        my $id = $cmd->add_host($testrun_id, $host);
        return $id;
}


sub add_feature
{
        my ($self, $testrun_id, $feature) = @_;
        my $cmd = Tapper::Cmd::Requested->new();
        my $id = $cmd->add_feature($testrun_id, $feature);
        return $id;
}

sub analyse_preconditions
{
        my ($self, @ids) = @_;
}


=head2 parse_interdep

Parse an interdep scenario and do everything needed to put it into the
database.

@param hash ref - config containing all relevant information
@param hash ref - options

@return success - 0
@return error   - die with error text

=cut

sub parse_interdep
{
        my ($self, $conf, $opt) = @_;

        my $scenario = Tapper::Cmd::Scenario->new();

        my $sc_id    = $scenario->add({type => 'interdep'});
        my @testrun_ids;
        foreach my $testrun (@$conf) {
                my $tr = Tapper::Cmd::Testrun->new();
                $testrun->{scenario_id} = $sc_id;
                my $testrun_id = $tr->add($testrun);
                push @testrun_ids, $testrun_id;
                my $precondition = Tapper::Cmd::Precondition->new();
                my @ids = $precondition->add($testrun->{preconditions});
                my $retval = $precondition->assign_preconditions($testrun_id, @ids);

        }
        if ($opt->{quiet}) {
                say $sc_id;
        } else {
                say "scenario $sc_id consists of testruns ",join ", ",@testrun_ids;
        }

}



# perl -Ilib bin/tapper-testrun new --topic=Software --precondition=14  --owner=ss5

1;
