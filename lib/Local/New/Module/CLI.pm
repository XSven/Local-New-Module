#!perl

use strict;
use warnings;

package Local::New::Module::CLI;

our $VERSION = 'v1.0.0';

use File::Basename qw( basename );
use Getopt::Std    qw( getopts );
use POSIX          qw( EXIT_SUCCESS );

sub run ( \@ );

exit run @ARGV if $0 eq __FILE__;

sub run ( \@ ) {
  local @ARGV = @{ $_[ 0 ] };

  my $opts;
  {
    my $warning;
    local $SIG{ __WARN__ } = sub { $warning = shift };
    # getopts() function returns true unless an invalid option was found
    unless ( getopts( '-Vh', $opts = {} ) ) {
      print STDERR $warning;
      return 2
    }
  }

  my $script_name = basename( $0 );
  if ( $opts->{ V } ) {
    # should direct the script to print information about its name, version,
    # origin and legal status, all on standard output, and then exit successfully
    print STDOUT "$script_name $VERSION\n";
    return EXIT_SUCCESS
  } elsif ( $opts->{ h } ) {
    # should output brief documentation for how to invoke the script, on
    # standard output, then exit successfully
    print STDOUT "Usage: $script_name [ -V | -h  ]\n", "       $script_name ...\n";
    return EXIT_SUCCESS
  }

  EXIT_SUCCESS
}

1
