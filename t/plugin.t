## no critic (RequireExtendedFormatting)

use strict;
use warnings;

use Test::More import => [ qw( can_ok like plan require_ok subtest ) ], tests => 3;
use Test::Fatal qw( exception );

my $plugin_name = 'MyProvePlugin';

require_ok( $plugin_name );

can_ok( $plugin_name, 'load' );

subtest 'provoke fatal perl diagnostics' => sub {
  plan tests => 3;

  like exception { $plugin_name->load }, qr/\ACan't use an undefined value as/, 'pass no aruments';

  like exception { $plugin_name->load( [] ) }, qr/\ANot a HASH reference/, 'pass wrong reference type';

  like exception { $plugin_name->load( 'foo' ) }, qr/\ACan't use string/, 'pass string(scalar) argument'
}
