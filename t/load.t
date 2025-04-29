use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT note plan use_ok ) ];

use Config qw( %Config );

my @module = qw( Local::New::Module Local::Test );

# https://metacpan.org/pod/perlsecret#Venus
# Venus operator ("0+") that does numification
plan tests => 0 + @module;

note "Perl $] at $^X";
note 'Harness ',       $ENV{ HARNESS_VERSION } if exists $ENV{ HARNESS_VERSION };
note 'Test::More ',    Test::More->VERSION;
note 'Test::Builder ', Test::Builder->VERSION;
note join "\n  ",      'PERL5LIB:', split( /$Config{ path_sep }/, $ENV{ PERL5LIB } ) if exists $ENV{ PERL5LIB };
note join "\n  ",      '@INC:',     @INC;
note join "\n  ",      'PATH:',     split( /$Config{ path_sep }/, $ENV{ PATH } );

for my $module ( @module ) {
  # if you want to use a module but not import anything, use require_ok()
  # instead of use_ok()
  use_ok $module or BAIL_OUT "Cannot load module '$module'";
  no warnings 'uninitialized'; ## no critic (ProhibitNoWarnings)
  note "Testing $module " . $module->VERSION
}
