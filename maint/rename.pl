#!/usr/bin/env perl

use feature qw( say );
use strict;
use warnings;

use File::Find      qw( find );
use File::Slurp     qw( edit_file_lines );
use File::Spec      ();
use Module::Runtime qw( module_notional_filename );

unless ( @ARGV == 3 ) {
  say STDERR $0, ' <top directory> <from main module> <to main module>';
  exit 1;
}

my ( $top_directory, $from_main_module, $to_main_module ) = @ARGV;

# from
( my $from_distname              = $from_main_module ) =~ s/::/-/g;
( my $from_main_module_namespace = $from_main_module ) =~ s/::/ /g;
my $from_main_module_file = module_notional_filename( $from_main_module );
( my $from_main_module_podfile = $from_main_module_file ) =~ s/\.pm\z/.pod/;

# to
( my $to_distname              = $to_main_module ) =~ s/::/-/g;
( my $to_main_module_namespace = $to_main_module ) =~ s/::/ /g;
my $to_main_module_file = module_notional_filename( $to_main_module );
( my $to_main_module_podfile = $to_main_module_file ) =~ s/\.pm\z/.pod/;

sub modify {
  s/$from_main_module/$to_main_module/g;
  s/$from_main_module_namespace/$to_main_module_namespace/g;
  s/$from_main_module_file/$to_main_module_file/g;
  s/$from_main_module_podfile/$to_main_module_podfile/g;
  s/$from_distname/$to_distname/g;
}

my $dot_git_directory = File::Spec->catfile( $top_directory, '.git' );

sub wanted {
  if ( $_ eq $dot_git_directory ) {
    $File::Find::prune = 1
  } else {
    if ( -f $_ ) {
      say;
      edit_file_lines( \&modify, $_ );
    }
  }
}

find( { wanted => \&wanted, no_chdir => 1 }, $top_directory );

