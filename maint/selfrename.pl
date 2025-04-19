#!/usr/bin/env perl

use feature qw( say );
use strict;
use warnings;

use File::Find            qw( find );
use File::Spec::Functions qw( catfile );

unless ( @ARGV == 2 ) {
  say STDERR $0, ' <top directory> <to main module>';
  exit 1;
}

my ( $top_directory, $to_main_module ) = @ARGV;

my @to_main_module_namespace = split /::/, $to_main_module;

#require( catfile( $top_directory, 'Makefile.PL' ) )->{ NAME };

my $dot_git_directory = catfile( $top_directory, '.git' );

# https://stackoverflow.com/questions/31024980/perl-in-place-editing-within-a-script-rather-than-one-liner
sub wanted {
  if ( $_ eq $dot_git_directory ) {
    $File::Find::prune = 1
  } else {
    if ( -f $_ ) {
      say;    # debug output
      local $ARGV[ 0 ] = $_;
      while ( <ARGV> ) {
        s/Local(::| |-|\/)New\1Module/join( $1, @to_main_module_namespace )/eg;
        print;
      }
    }
  }
}

our $^I = '';    # enable inplace-edit
find( { wanted => \&wanted, no_chdir => 1 }, $top_directory );
