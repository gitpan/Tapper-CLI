package Tapper::CLI::Testrun;
BEGIN {
  $Tapper::CLI::Testrun::AUTHORITY = 'cpan:TAPPER';
}
{
  $Tapper::CLI::Testrun::VERSION = '4.1.3';
}

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

__END__

=pod

=encoding utf-8

=head1 NAME

Tapper::CLI::Testrun

=head1 AUTHOR

AMD OSRC Tapper Team <tapper@amd64.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Advanced Micro Devices, Inc..

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut
