use strict;
use warnings;

use File::Spec::Functions qw( catfile rel2abs );

# load standard dependencies file (do not change this file!)
require &rel2abs( catfile( qw( maint cpanfile ) ) );

on configure => sub { };

on runtime => sub { };

on test => sub { };

on develop => sub { }
