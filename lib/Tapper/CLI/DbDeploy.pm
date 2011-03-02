package Tapper::CLI::DbDeploy;

use strict;
use warnings;

use Tapper::Model 'model';
use parent 'App::Cmd';

sub opt_spec
{
        my ( $class, $app ) = @_;

        return (
                [ 'help' => "This usage screen" ],
                $class->options($app),
               );
}

sub global_opt_spec {
        return (
                [ 'l'    => "Prepend ./lib/ to module search path \@INC" ],
               );
}


sub execute_command
{
        my ($cmd, $opt, $args) = @_;

        if ($cmd->global_options->{l}) {
                eval "use lib './lib/'"; ## no critic
        }

        App::Cmd::execute_command(@_);
}

# sub validate_args
# {
#         my ( $self, $opt, $args ) = @_;

#         die $self->_usage_text if $opt->{help};
#         use Data::Dumper;
#         $self->validate( $opt, $args );
# }

1;
