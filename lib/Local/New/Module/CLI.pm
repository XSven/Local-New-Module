#!perl

use strict;
use warnings;

package Local::New::Module::CLI;

# keeping the following $VERSION declaration on a single line is important
#<<<
use version 0.9915 qw( ); our $VERSION = version->declare( '1.0.0' );
#>>>

use Getopt::Std qw( getopts );
use POSIX       qw( EXIT_SUCCESS );

use vars qw( @CARP_NOT );
use constant CALLER_IS_REQUIRE => 7;

sub run ( \@ );
sub _croakf ( $@ );

exit run @ARGV unless ( caller( 0 ) )[ CALLER_IS_REQUIRE ];

sub run ( \@ ) {
  local @ARGV = @{ $_[ 0 ] };

  my $opts;
  {
    local $SIG{ __WARN__ } = sub {
      local @CARP_NOT = qw( Getopt::Std );
      my $warning = shift;
      chomp $warning;
      _croakf $warning;
    };
    getopts( '-Vh', $opts = {} );
  }
  if ( $opts->{ V } ) {
    print STDOUT "cli-tool $VERSION\n";
    return EXIT_SUCCESS
  } elsif ( $opts->{ h } ) {
    print STDOUT "Usage: cli-tool [ -V | -h  ]\n", "       cli-tool ...\n";
    return EXIT_SUCCESS
  }

  EXIT_SUCCESS
}

sub _croakf ( $@ ) {
  require Carp;
  @_ = ( ( @_ == 1 ? shift : sprintf shift, @_ ) . ', stopped' );
  goto &Carp::croak;
}

1
