package Tapper::CLI::Testrun::Command::newtestplan;
BEGIN {
  $Tapper::CLI::Testrun::Command::newtestplan::AUTHORITY = 'cpan:AMD';
}
{
  $Tapper::CLI::Testrun::Command::newtestplan::VERSION = '4.0.1';
}

use 5.010;

use strict;
use warnings;
no warnings 'uninitialized';

use parent 'App::Cmd::Command';
use Cwd;

use Tapper::Reports::DPath::TT;
use Tapper::Cmd::Testplan;
use Tapper::Config;

sub abstract {
        'Create a new testplan instance';
}


my $options = { "verbose" => { text => "some more informational output",                     short => 'v' },
                "dryrun"  => { text => "Just print evaluated testplan without submit to DB", short => 'n' },
                "guide"   => { text => "Just print self-documentation",                      short => 'g' },
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
        "tapper-testrun newtestplan --file=s  [ -n ] [ -v ] [ -Dkey=value ] [ --path=s ] [ --name=s ] [ --include=s ]*";
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


sub print_result
{
        my ($self, $plan_id) = @_;


        return;
}



sub get_shortname{
        my ($self, $plan, $name) = @_;
        return $name if $name;

        foreach my $line (split "\n", $plan) {
                if ($line =~/^###\s*(?:short)?name\s*:\s*(.+)$/i) {
                        return $1;
                }
        }
        return;
}


sub execute
{
        my ($self, $opt, $args) = @_;

        use File::Slurp 'slurp';
        my $plan = slurp($opt->{file});

        $plan = $self->apply_macro($plan, $opt->{d}, $opt->{include});

        if ($opt->{guide}) {
                my $guide = $plan;
                my @guide = grep { m/^###/ } split (qr/\n/, $plan);
                say "Self-documentation:";
                say map { my $l = $_; $l =~ s/^###/ /; "$l\n" } @guide;
                return 0;
        }

        if ($opt->{dryrun}) {
                say $plan;
                return 0;
        }

        my $cmd = Tapper::Cmd::Testplan->new();
        my $path = $opt->{path};
        $path = $self->parse_path($opt->{file}) if not $path;

        my $shortname = $self->get_shortname($plan, $opt->{name});
        my $plan_id = $cmd->add($plan, $path, $shortname);
        die "Plan not created" unless defined $plan_id;

        if ($opt->{verbose}) {
                my $url = Tapper::Config->subconfig->{base_url} || 'http://tapper/tapper';
                say "Plan created";
                say "  id:   $plan_id";
                say "  url:  $url/testplan/id/$plan_id";
                say "  path: $path";
                say "  file: ".$opt->{file};
        } else {
                say $plan_id;
        }
        return 0;
}


sub apply_macro
{
        my ($self, $macro, $substitutes, $includes) = @_;

        my @include_paths = (Tapper::Config->subconfig->{paths}{testplan_path});
        push @include_paths, @{$includes || [] };
        my $include_path_list = join ":", @include_paths;

        my $tt = Tapper::Reports::DPath::TT->new(include_path => $include_path_list,
                                                 substitutes  => $substitutes,
                                                );
        return $tt->render_template($macro);
}

1;

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::Testrun::Command::newtestplan

=head2 parse_path

Get the test plan path from the filename. This is a little more tricky
since we do not simply want the dirname.

@param string - file name

@return string - test plan path

=head2 print_result

Format and print more detailled information on the new testplan.

@param int - testplan instance id

=head2 get_shortname

Get the shortname for this testplan. The shortname is either given as
command line option or inside the plan text.

@param string - plan text
@param string - value of $opt->{name}

@return string - shortname

=head2 execute

Worker function

=head2 apply_macro

Process macros and substitute using Template::Toolkit.

@param string  - contains macros
@param hashref - containing substitutions
@optparam string - path to more include files

@return success - text with applied macros
@return error   - die with error string

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

