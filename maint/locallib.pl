use strict;
use warnings;

use lib ();

use File::Spec::Functions qw( catdir catfile rel2abs );

# This module file (.pl) returns a sub that creates all kind of local lib
# related variables used in maint/MY.pm.
# Call:
# my ( $local_lib_root, $local_bin, $local_lib_rel, $local_lib, $t_lib_rel, $prove_rc_file ) =
#   ( require &rel2abs( catfile( qw( maint locallib.pl ) ) ) )->( $ARGV[ 0 ] );
# Issues:
# - t_lib_rel isn't local lib related
# - lib->import() changes @INC (bad side effect)
sub {
  my $arg = shift;

  my ( $local_lib_root, $local_bin, $local_lib_rel, $local_lib, $t_lib_rel, $prove_rc_file );

  $local_lib_root = rel2abs( $arg );

  $local_bin = catfile( $local_lib_root, qw( bin ) );

  $local_lib_rel = catdir( $arg, qw( lib perl5 ) );
  $local_lib     = rel2abs( $local_lib_rel );
  # need to prepend local library path to locate ExtUtils::MakeMaker::CPANfile
  # and other configure related modules
  lib->import( $local_lib );

  $t_lib_rel = catdir( qw( t lib ) );

  $prove_rc_file = rel2abs( catfile( qw( t .proverc ) ) );
  return ( $local_lib_root, $local_bin, $local_lib_rel, $local_lib, $t_lib_rel, $prove_rc_file )
}
