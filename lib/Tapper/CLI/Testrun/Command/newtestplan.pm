package Tapper::CLI::Testrun::Command::newtestplan;

use 5.010;

use strict;
use warnings;
no warnings 'uninitialized';

use parent 'App::Cmd::Command';
use Cwd;

use Tapper::Cmd::Testplan;
use Tapper::Config;

sub abstract {
        'Create a new testplan instance';
}


my $options = { "verbose" => { text => "some more informational output"                                         },
                "D"       => { text => "Define a key=value pair used for macro expansion",   type => 'keyvalue' },
                "file"    => { text => "String; use (macro) testplan file",                  type => 'string'   },
                "path"    => { text => "String; put this path into db instead of file path", type => 'string'   },
                "include" => { text => "String; add include directory (multiple allowed)",   type => 'manystring', short => 'I' },
                "name"    => { text => "String; provide a name for this testplan instance",  type => 'string'   },
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
        my $allowed_opts = join ' ', map { '--'.$_ } _allowed_opts();
        "tapper-testrun newtestplan  [ " . $allowed_opts ." ]";
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

        die "Testplan file needed\n",$self->usage->text if not $opt->{file};
        die "Testplan file ",$opt->{file}," does not exist" if not -e $opt->{file};
        die "Testplan file ",$opt->{file}," is not readable" if not -r $opt->{file};

        return 1;
}

=head2 parse_path

Get the test plan path from the filename. This is a little more tricky
since we do not simply want the dirname.

@param string - file name

@return string - test plan path

=cut

sub parse_path
{
        my ($self, $filename) = @_;
        $filename = Cwd::abs_path($filename);
        my $basedir = Tapper::Config->subconfig->{paths}{testplan_path};
        # splitting filename at basedir returns an array with the empty
        # string before and the path after the basedir
        my $path = (split $basedir, $filename)[1]; 
        return $path;
}

=head2 print_result

Format and print more detailled information on the new testplan.

@param int - testplan instance id



=cut

sub print_result
{
        my ($self, $plan_id) = @_;


        return;
}

=head2 execute

Worker function

=cut

sub execute
{
        my ($self, $opt, $args) = @_;

        use File::Slurp 'slurp';
        my $plan = slurp($opt->{file});
        $plan = $self->apply_macro($plan, $opt->{d}, $opt->{include});
        
        my $cmd = Tapper::Cmd::Testplan->new();
        my $path = $opt->{path};
        $path = $self->parse_path($opt->{file}) if not $path;
        my $plan_id = $cmd->add($plan, $path, $opt->{name});
        die "Plan not created" unless defined $plan_id;
        if ($opt->{verbose}) {
                $self->print_result($plan_id);
        } else {
                say $plan_id;
        }
        return 0;
}

=head2 apply_macro

Process macros and substitute using Template::Toolkit.

@param string  - contains macros
@param hashref - containing substitutions
@optparam string - path to more include files


@return success - text with applied macros
@return error   - die with error string

=cut

sub apply_macro
{
        my ($self, $macro, $substitutes, $includes) = @_;

        use Template;

        my @include_paths = (Tapper::Config->subconfig->{paths}{testplan_path});
        push @include_paths, @{$includes || [] };
        my $include_path_list = join ":", @include_paths;

        my $tt = Template->new({
                               INCLUDE_PATH =>  $include_path_list,
                               });
        my $ttapplied;
        
        $tt->process(\$macro, $substitutes, \$ttapplied) || die $tt->error();
        return $ttapplied;
}





# perl -Ilib bin/tapper-testrun new --topic=Software --precondition=14  --owner=ss5

1;
