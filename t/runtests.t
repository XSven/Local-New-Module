use strict;
use warnings;

use Test::More import => [ qw( is ) ], tests => 4;
use Test::Deep            qw( cmp_bag );
use Test::Harness         ();
use Sub::Override         ();
use File::Spec::Functions qw( catfile rel2abs );

# mock
my $override = Sub::Override->new( 'Test::Harness::runtests', sub { ( \@INC, \@_ ) } );

# given
my @expected_test_files     = map { catfile( 't', $_ ) } qw( foo.t bar.t );
my $expected_number_of_libs = 3;
local @ARGV = ( 0, $expected_number_of_libs, 'lib1', 'lib2', 'lib3', @expected_test_files );

# when
my ( $got_inc, $got_test_files ) = do( rel2abs( catfile( qw( maint runtests.pl ) ) ) );

# then
cmp_bag( $got_test_files, \@expected_test_files, 'check test files' );
is scalar( grep { m/lib\d+\z/ } @$got_inc ), $expected_number_of_libs, 'count libs';

# given
@expected_test_files     = map { catfile( 't', $_ ) } qw( foo.t bar.t baz.t );
$expected_number_of_libs = 1;
local @ARGV = ( 0, $expected_number_of_libs, 'lib4', @expected_test_files );

# when
( $got_inc, $got_test_files ) = do( rel2abs( catfile( qw( maint runtests.pl ) ) ) );

# then
cmp_bag( $got_test_files, \@expected_test_files, 'check test files' );
is scalar( grep { m/lib\d+\z/ } @$got_inc ), $expected_number_of_libs, 'count libs';
