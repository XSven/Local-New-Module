use strict;
use warnings;

use ExtUtils::Command     qw();
use File::Spec::Functions qw( rel2abs );
use Test::Harness         qw( runtests );
use List::Util            qw( shuffle );
use lib                   qw();

$Test::Harness::verbose = shift; ## no critic (Variables::ProhibitPackageVars)
my @inc        = splice @ARGV, 0, 4;
my @test_files = @ARGV;

# restore default/original @INC
# https://metacpan.org/pod/lib#Restoring-original-@INC
local @INC = @lib::ORIG_INC;
# don't use lib::import because Test::Harness::runtests does this implicitly
unshift @INC, map { rel2abs( $_ ) } @inc;

runtests( shuffle( ExtUtils::Command::expand_wildcards( @test_files ) ) )
