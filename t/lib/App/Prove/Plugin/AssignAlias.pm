use strict;
use warnings;

# Normally it is an error to attempt to run the same test twice. Aliases allow
# you to overcome this limitation by giving each run of the test a unique name.
# https://metacpan.org/pod/TAP::Harness#runtests
package App::Prove::Plugin::AssignAlias;

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

    my @tmp = @$plugin_args;
    my %test_script_has_alias;
    while ( my ( $test_script, $alias ) = splice @tmp, 0, 2 ) {
      push @{ $test_script_has_alias{ $test_script } }, [ $test_script, $alias ];
    }

    my @tests;
    for ( $_get_tests_orig->( @_ ) ) {
      if ( exists $test_script_has_alias{ $_ } ) {
        push @tests, @{ $test_script_has_alias{ $_ } };
      } else {
        push @tests, $_;
      }
    }
    return @tests;
  };
}

1;
