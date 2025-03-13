use strict;
use warnings;

package App::Prove::Plugin::RunFirst;

use App::Prove               qw();
use Class::Method::Modifiers qw( around );

# The variables $plugin_name and $app_prove are not used but we keep them on
# purpose.
sub load {
  my $plugin_name = shift;
  my ( $app_prove, $plugin_args ) = @{ +shift }{ qw( app_prove args ) };

  # https://metacpan.org/dist/App-Prove-Plugin-Count/source/lib/App/Prove/Plugin/Count.pm
  around 'App::Prove::_get_tests' => sub {
    my $_get_tests_orig = shift;

    my @run_first_test_scripts = @$plugin_args ? @$plugin_args : 't/00-load.t';
    my %run_first_test_scripts;
    @run_first_test_scripts{ @run_first_test_scripts } = ();
    my @tests = ( @run_first_test_scripts, grep { not exists $run_first_test_scripts{ $_ } } $_get_tests_orig->( @_ ) );
    return @tests;
  };
}

1;
