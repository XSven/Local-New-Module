use strict;
use warnings;

use ExtUtils::Command     qw();
use File::Spec::Functions qw( file_name_is_absolute rel2abs );
use Test::Harness         qw( runtests );
use List::Util            qw( shuffle );
use lib                   qw();

$Test::Harness::verbose = shift; ## no critic (Variables::ProhibitPackageVars)
my $number_of_libs = shift;
my @inc            = splice @ARGV, 0, $number_of_libs;
my @test_files     = @ARGV;

# restore default/original @INC
# https://metacpan.org/pod/lib#Restoring-original-@INC
local @INC = @lib::ORIG_INC;
# don't use lib::import because Test::Harness::runtests does this implicitly
unshift @INC, grep { -d } map { file_name_is_absolute( $_ ) ? $_ : rel2abs( $_ ) } @inc;

runtests( shuffle( ExtUtils::Command::expand_wildcards( @test_files ) ) )
