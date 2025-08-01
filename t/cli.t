use strict;
use warnings;

use Test::Script tests => 5;

use File::Basename qw( basename );

my $script = 'blib/script/cli-tool';
script_compiles( $script );
script_runs( [ $script, '-V' ], "Script $script runs with -V" );
script_stdout_is basename( $script ) . " v1.0.0\n", 'Show version';
script_runs( [ $script, '-g' ], { exit => 2 }, "Script $script runs with unknown option" );
script_stderr_is "Unknown option: g\n", 'Report error';
