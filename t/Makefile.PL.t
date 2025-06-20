use strict;
use warnings;

use Test::More import => [ qw( is ok ) ], tests => 3;

# Makefile.PL as a modulino
# https://www.masteringperl.org/2015/01/makefile-pl-as-a-modulino/
my $att = do './Makefile.PL';

is ref $att, 'HASH', 'WriteMakefile() returns HASH ref attributes structure';
ok exists $att->{ NAME },                            'main module NAME is set';
ok exists $att->{ TEST_REQUIRES }->{ 'Test::More' }, 'Test::More is a required test dependency (TEST_REQUIRES)';
