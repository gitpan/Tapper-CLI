package Tapper::CLI::DbDeploy;
BEGIN {
  $Tapper::CLI::DbDeploy::AUTHORITY = 'cpan:AMD';
}
{
  $Tapper::CLI::DbDeploy::VERSION = '4.0.1';
}

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

__END__
=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::DbDeploy

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

