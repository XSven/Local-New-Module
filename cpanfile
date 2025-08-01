use strict;
use warnings;

use File::Spec::Functions qw( catfile rel2abs );

# load standard dependencies file (do not change this file!)
require &rel2abs( catfile( qw( maint cpanfile ) ) );

on configure => sub { };

on runtime => sub { };

on test => sub {
  requires 'File::Temp'    => '0';
  requires 'Test::Deep'    => '0' if $] >= 5.012;
  requires 'Sub::Override' => '0'
};

on develop => sub { }
