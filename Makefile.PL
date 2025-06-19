use strict;
use warnings;

use Carp                  qw( croak );
use File::Spec::Functions qw( catfile rel2abs );

BEGIN {
  # pass cpm's default --local-lib-contained DIR to the required MY module using
  # the localized first element of @ARGV
  local $ARGV[ 0 ] = 'local';
  require &rel2abs( catfile( qw( maint MY.pm ) ) )
}

use ExtUtils::MakeMaker::CPANfile;    # do not supply an empty list because import() has to be called
use File::ShareDir::Install qw( install_share );

for ( qw( EMAIL FULL_NAME ) ) {
  croak "$_ environment variable is not set, stopped" unless exists $ENV{ $_ };
}

my @main_module_namespace = qw( Local New Module );
my $version               = '1.0.0';
my $release_status        = 'unstable';               # transition: unstable => testing => stable

my $distname            = join '-',  @main_module_namespace;
my $main_module         = join '::', @main_module_namespace;
my $main_module_file    = catfile( @main_module_namespace ) . '.pm';
my $main_module_podfile = catfile( @main_module_namespace ) . '.pod';
my %att                 = (
  NAME          => $main_module,
  AUTHOR        => "$ENV{ FULL_NAME } <$ENV{ EMAIL }>",
  VERSION_FROM  => catfile( 'lib', $main_module_file ),
  ABSTRACT_FROM => catfile( 'lib', $main_module_podfile ),
  # another valid license string is "restricted"
  # https://metacpan.org/pod/CPAN::Meta::Spec#license
  LICENSE          => 'perl_5',
  MIN_PERL_VERSION => '5.14.4',
  # safe naming of custom arguments passed to Makefile.PL
  # https://github.com/Perl-Toolchain-Gang/ExtUtils-MakeMaker/issues/470
  DISTVNAME => "$distname-$version"
    . ( $release_status ne 'stable' ? '-TRIAL1' : '' ),    # related to the below release_status metadata field
  EXE_FILES  => [ glob( join( ' ', map { catfile( $_, '*' ) } qw( bin script ) ) ) ],
  META_MERGE => {
    'meta-spec'    => { version => 2 },
    release_status => $release_status,
    provides       => {
      $main_module => {
        file    => catfile( 'lib', $main_module_file ),
        version => $version
      }
    },
    resources => {
      repository => {
        type => 'git',
        url  => "git://github.com/XSven/$distname.git",
        web  => "https://github.com/XSven/$distname"
      },
      bugtracker => {
        web => "https://github.com/XSven/$distname/issues"
      }
    }
  },
  # check ExtUtils::MakeMaker Changes
  NORECURS  => 1,
  PL_FILES  => {},
  PM        => { map { catfile( 'lib', $_ ) => catfile( '$(INST_LIB)', $_ ) } ( $main_module_file ) },
  clean     => { FILES                => "$distname* cover_db" },
  dist      => { TARFLAGS             => 'cf', COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
  realclean => { FILES                => 'local' },
  test      => { RECURSIVE_TEST_FILES => 1 }
);

# "dist" refers to the $(DISTNAME) macro variable
# install_share dist => 'share';
# install_share module => $main_module => 'share';

# Makefile.PL as a modulino
# https://www.masteringperl.org/2015/01/makefile-pl-as-a-modulino/
if ( caller() ) {
  no warnings qw( redefine );
  # redefine ExtUtils::MakeMaker::WriteMakefile() to echo its atributes
  *ExtUtils::MakeMaker::WriteMakefile = sub {
    +{ @_ }    # \%att
  };
  # re-trigger the ExtUtils::MakeMaker::WriteMakefile() modification
  ExtUtils::MakeMaker::CPANfile->import
}
WriteMakefile( %att )
