package Tapper::CLI::Testrun::Command::listprecondition;

use 5.010;

use strict;
use warnings;

use parent 'App::Cmd::Command';

use Tapper::Model 'model';

sub abstract {
        'List preconditions'
}

my $options = { "verbose"     => { text => "Show all information of preconditions, otherwise only show ids", short => 'v' },
                "nonewlines"  => { text => "escape newlines in values to avoid multilines" },
                "quotevalues" => { text => "put quotes around the values", short => 'q' },
                "colnames"    => { text => "print out column names", short => 'c' },
                "all"         => { text => "list all preconditions", needed => 1, short => 'a' },
                "testrun"     => { text => "assigned to given testrun id", needed => 1, type => 'multiint' },
                "id"          => { text => "list particular precondition", needed => 1, type => 'multiint', short => 'i'  },
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
                        when ("int")           {$pushkey .="=i";}
                        when ("multiint")      {$pushkey .="=i@";}
                        when ("keyvalue")      {$pushkey .="=s%";}
                }
                push @opt_spec, [$pushkey, $options->{$key}->{text}];
        }
        return (
                @opt_spec
               );
}

sub usage_desc {
        my $allowed_opts = join ' | ', map { '--'.$_ } _allowed_opts();
        "tapper-testrun listprecondition [ " . $allowed_opts ." ]";
}

sub _allowed_opts {
        my @allowed_opts = map { $_->[0] } opt_spec();
}

sub _extract_bare_option_names {
        map { my $x = $_; $x =~ s/=.*//; $x } _allowed_opts();
}

sub validate_args {
        my ($self, $opt, $args) = @_;
        my @allowed_opts;
        foreach my $key (keys %$options) {
                push @allowed_opts, $key if  $options->{$key}->{needed};
        }
        
        my $msg = "Unknown option";
        $msg   .= ($args and $#{$args} >=1) ? 's' : '';
        $msg   .= ": ";
        say STDERR $msg, join(', ',@$args) if ($args and @$args);
        
        
        my $allowed_opts_re = join '|', @allowed_opts;

        return 1 if grep /$allowed_opts_re/, keys %$opt;
        die $self->usage->text;
}

sub execute {
        my ($self, $opt, $args) = @_;

        $self->$_ ($opt, $args) foreach grep /^(all|lonely|primary|pre|id|testrun)$/, keys %$opt;
}

=head2 testrun

Return all preconditions for a given testrun id.

=cut

sub testrun
{ 
        my ($self, $opt, $args) = @_;
        my @ids = @{ $opt->{testrun} };
        $self->print_colnames($opt, $args);
        
        my $preconditions = model('TestrunDB')->resultset('TestrunPrecondition')->search({testrun_id => @ids}, { order_by => 'precondition_id' });
        while (my $precond = $preconditions->next) {
                if ($opt->{verbose}) {
                        my $precond_yaml = model('TestrunDB')->resultset('Precondition')->search({id => $precond->precondition_id});
                        foreach my $yaml($precond_yaml->next) {
                                print $yaml->to_string($opt)."\n";
                        }

                } else {
                        say $precond->precondition_id;

                }
        }
        

}

sub print_colnames
{
        my ($self, $opt, $args) = @_;

        return unless $opt->{colnames};

        my $columns = model('TestrunDB')->resultset('Precondition')->result_source->{_ordered_columns};
        print join( $Tapper::Schema::TestrunDB::DELIM, @$columns, '' ), "\n";
}

sub all
{
        my ($self, $opt, $args) = @_;

        print "| Id |\n------\n" if $opt->{id_only};
        $self->print_colnames($opt, $args);

        my $preconditions = model('TestrunDB')->resultset('Precondition')->search({}, { order_by => 'id' });
        while (my $precond = $preconditions->next) {
                if ($opt->{verbose}) {
                        print $precond->to_string($opt)."\n";
                } else {
                        say $precond->id;
                }
        }
}


sub id
{
        my ($self, $opt, $args) = @_;

        my @ids = @{ $opt->{id} };

        $self->print_colnames($opt, $args);
        foreach (@ids) {
                my $entry = _get_entry_by_id($_);
                say $entry ? $entry->to_string($opt) : "No such id $_";
        }
}

# --------------------------------------------------

sub _get_entry_by_id {
        my ($id) = @_;
        model('TestrunDB')->resultset('Precondition')->find($id);
}

1;

# perl -Ilib bin/tapper-testrun listprecondition --all --colnames
# perl -Ilib bin/tapper-testrun listprecondition --all --colnames --nonewlines 
# perl -Ilib bin/tapper-testrun listprecondition --all --colnames --nonewlines --quotevalues
