package Tapper::CLI::Testrun;

use strict;
use warnings;

use parent 'App::Cmd';

sub opt_spec
{
        my ( $class, $app ) = @_;

        return (
                [ 'help' => "This usage screen" ],
                $class->options($app),
               );
}

sub validate_args
{
        my ( $self, $opt, $args ) = @_;

        die $self->_usage_text if $opt->{help};
        $self->validate( $opt, $args );
}

1;

