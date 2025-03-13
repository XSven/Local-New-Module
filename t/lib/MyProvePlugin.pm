use strict;
use warnings;

package MyProvePlugin;

sub load {
  # Class name of this plugin.
  my $plugin_name = shift;
  # App::Prove (prove) object reference and arguments passed to this plugin.
  # Note that the HASH keys "app_prove" and "args" that are used in the HASH
  # slice are part of the load() signature definition: DO NOT CHANGE THEM!
  my ( $app_prove, $plugin_args ) = @{ +shift }{ qw( app_prove args ) };
}

1;
