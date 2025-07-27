use strict;
use warnings;

use Test::More import => [ qw( ) ], tests => 3;
use Test::Script qw( script_compiles );

use File::Basename qw( basename );
use POSIX          qw( EXIT_SUCCESS );

my $script = 'blib/script/cli-tool';
script_compiles( $script );
script_runs( [ $script, '-V' ], { exit => EXIT_SUCCESS }, "Script $script runs with -V" );
script_stdout_is basename( $script ) . " 1.0.0\n", 'Show version'
