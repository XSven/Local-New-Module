use strict;
use warnings;

use Carp                  qw( croak );
use File::Find            qw( find );
use File::Spec::Functions qw( catfile curdir rel2abs );

my $project_dir = rel2abs( curdir );
my $maker_file  = catfile( $project_dir, 'Makefile.PL' );
croak "$maker_file missing in project directory, stopped"
  unless -f $maker_file;

croak "Required target main module not specified, stopped" unless @ARGV;
my ( $target_main_module ) = @ARGV;

my @target_main_module_namespace = split /::/, $target_main_module;

my $dot_git_directory = catfile( $project_dir, '.git' );

# https://stackoverflow.com/questions/31024980/perl-in-place-editing-within-a-script-rather-than-one-liner
sub wanted {
  if ( $_ eq $dot_git_directory ) {
    $File::Find::prune = 1
  } else {
    if ( -f $_ ) {
      local $ARGV[ 0 ] = $_;
      while ( <ARGV> ) {
        s/Local(::| |-|\/)New\1Module/join( $1, @target_main_module_namespace )/eg;
        print;
      }
    }
  }
}

local $^I = '';    # enable inplace-edit
find( { wanted => \&wanted, no_chdir => 1 }, $project_dir );
