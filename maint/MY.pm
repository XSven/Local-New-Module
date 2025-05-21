use strict;
use warnings;

package MY;

use lib  ();
use subs qw( _local _which );

use Config                qw( %Config );
use File::Basename        qw( basename );
use File::Spec::Functions qw( catdir catfile rel2abs );
use Module::Loaded        qw( is_loaded );

my ( $local_lib_root, $local_bin, $local_lib_rel, $local_lib ) = _local $ARGV[ 0 ];
my $t_lib = rel2abs( catdir( qw( t lib ) ) );

# need to prepend local library path to locate ExtUtils::MakeMaker::CPANfile
# and other configure related modules
lib->import( $local_lib ) if defined $local_lib;

if ( defined $local_bin ) {
  # do not use "local" in the following line because then _which() will no see
  # the modified PATH
  if ( exists $ENV{ PATH } ) {
    $ENV{ PATH } = "$local_bin$Config{ path_sep }$ENV{ PATH }" ## no critic (RequireLocalizedPunctuationVars)
      unless grep { $local_bin eq $_ } split $Config{ path_sep }, $ENV{ PATH };
  } else {
    $ENV{ PATH } = $local_bin; ## no critic (RequireLocalizedPunctuationVars)
  }
}

# https://metacpan.org/pod/ExtUtils::MakeMaker#Overriding-MakeMaker-Methods

# new feature: allow fullcheck() to return a boolean value in scalar context
# https://github.com/Perl-Toolchain-Gang/ExtUtils-Manifest/issues/45
sub dist_basics {
  my ( $self ) = @_;

  my $inherited = $self->SUPER::dist_basics;
  $inherited =~ s/fullcheck$/'exit( scalar( map { \@\$\$_ } fullcheck() ) ? 1 : 0 )'/m;
  $inherited
}

sub dist_test {
  my ( $self ) = @_;

  my $inherited = $self->SUPER::dist_test;
  $inherited =~ s/^(disttest ?:.+)$/$1\n\t\$(CP) -R $local_lib_root \$(DISTVNAME)/m if defined $local_lib_root;
  # https://github.com/Perl-Toolchain-Gang/toolchain-site/blob/master/oslo-consensus.md#release_testing
  $inherited =~ s/( test )/$1RELEASE_TESTING=1 /m;
  $inherited
}

# test_* PHONY targets
# https://metacpan.org/pod/ExtUtils::MM_Unix#test_via_harness-(override)
sub test_via_harness {
  my ( $self, $perl, $tests ) = @_;

  my @extra_libs = defined $local_lib ? ( $local_lib ) : split /$Config{ path_sep }/,
    ( exists $ENV{ PERL5LIB } ? $ENV{ PERL5LIB } : '' );
  my $extra_libs     = @extra_libs ? '"' . join( '" "', @extra_libs ) . '"' : '';
  my $number_of_libs = 3 + @extra_libs;

  "\tPERL_DL_NONLAZY=1 $perl ${ \( defined $local_lib ? \"-Mlib=$local_lib\" : '' ) } "
    . rel2abs( catfile( qw( maint runtests.pl ) ) )
    . " \"\$(TEST_VERBOSE)\" $number_of_libs \"\$(INST_ARCHLIB)\" \"\$(INST_LIB)\" \"$t_lib\" $extra_libs $tests\n"
}

# testdb_* PHONY targets
# https://metacpan.org/pod/ExtUtils::MM_Unix#test_via_script-(override)
sub test_via_script {
  my ( $self, $perl, $tests ) = @_;

  # TODO: make $t_lib an extra lib and apply -d check on all extra libs
  my @extra_libs = defined $local_lib ? ( $local_lib ) : split /$Config{ path_sep }/,
    ( exists $ENV{ PERL5LIB } ? $ENV{ PERL5LIB } : '' );
  my $extra_libs = @extra_libs ? '"-I' . join( '" "-I', @extra_libs ) . '"' : '';

  "\tPERL_DL_NONLAZY=1 $perl \"-I\$(realpath \$(INST_ARCHLIB))\" \"-I\$(realpath \$(INST_LIB))\" \"-I$t_lib\" $extra_libs $tests\n"
}

# https://metacpan.org/pod/ExtUtils::MM_Any#postamble-(o)
sub postamble {
  my ( $self ) = @_;

  my $make_fragment = '';

  $make_fragment .= <<"MAKE_FRAGMENT";
export PATH := $ENV{ PATH }
undefine PERL5LIB
MAKE_FRAGMENT

  $make_fragment .= <<"MAKE_FRAGMENT";

# runs the last modified test script
.PHONY: testlm
testlm:
	\$(NOECHO) \$(MAKE) TEST_FILES=\$\$(perl -e 'print STDOUT ( sort { -M \$\$a > -M \$\$b } glob( "\$\$ARGV[0]" ) )[0]' '\$(TEST_FILES)') test
MAKE_FRAGMENT

  my $prove = _which 'prove';
  if ( defined $prove and defined $local_lib ) {
    my $prove_rc_file = rel2abs( catfile( qw( t .proverc ) ) );
    $make_fragment .= <<"MAKE_FRAGMENT";

# runs test scripts through TAP::Harness (prove) instead of Test::Harness (ExtUtils::MakeMaker)
# https://metacpan.org/dist/Test-Harness/view/bin/prove#\@INC
.PHONY: testp
testp: pure_all
	\$(NOECHO) \$(FULLPERLRUN) -I$local_lib $prove\$(if \$(TEST_VERBOSE:0=), --verbose) --norc${ \( -f $prove_rc_file ? " --rc $prove_rc_file" : '' ) } --blib${ \( -d $t_lib  ? " -I$t_lib" : '' ) } -I$local_lib -w --recurse --shuffle \$(TEST_FILES)
MAKE_FRAGMENT
  }

  my $cover = _which 'cover';
  $make_fragment .= <<"MAKE_FRAGMENT" if defined $cover and defined $local_lib;

.PHONY: cover
cover:
	\$(NOECHO) \$(FULLPERLRUN) -I$local_lib $cover -delete
	\$(NOECHO) HARNESS_PERL_SWITCHES=-MDevel::Cover \$(MAKE) test
	\$(NOECHO) \$(FULLPERLRUN) -I$local_lib $cover -select_re '\\A(?:blib|maint)/.*\\.pm|\\Amaint/.*\\.pl' -coverage statement -coverage branch -coverage condition -coverage subroutine -report vim
MAKE_FRAGMENT

  my $podman = _which 'podman';
  $make_fragment .= <<"MAKE_FRAGMENT" if defined $podman and defined $local_lib;

.PHONY: imagebuild
imagebuild: distcheck dist
	\$(NOECHO) \$(FULLPERLRUN) -s ${ \( rel2abs( catfile( qw( maint containerfile.pl ) ) ) ) } -Tardist=\$(DISTVNAME).tar\$(SUFFIX) -Distvname=\$(DISTVNAME) -Inst_archlib=\$(INST_ARCHLIB) -Inst_lib=\$(INST_LIB) -Local_lib_rel=$local_lib_rel -Exe_file=\$(INST_SCRIPT)\$(DFSEP)\$(notdir \$(EXE_FILES)) | \\
	$podman image build --no-cache --env FULL_NAME=\"\$(FULL_NAME)\" --env EMAIL=\"\$(EMAIL)\" --tag \$(notdir \$(EXE_FILES)):\$(VERSION) --file - .
MAKE_FRAGMENT

  $make_fragment .= join "\n", '', File::ShareDir::Install::postamble( $self )
    if is_loaded 'File::ShareDir::Install';

  $make_fragment
}

sub _which ( $ ) {
  my ( $executable ) = @_;

  for ( split /$Config{ path_sep }/, $ENV{ PATH } ) { ## no critic (RequireExtendedFormatting)
    my $file = catfile( $_, $executable );
    return $file if -x $file
  }

  undef
}

sub _local ( $ ) {
  my ( $arg ) = @_;

  my ( $local_lib_root, $local_bin, $local_lib_rel, $local_lib ); ## no critic (ProhibitReusedNames)

  if ( -d $arg ) {
    $local_lib_root = rel2abs( $arg );

    $local_bin = catfile( $local_lib_root, qw( bin ) );

    $local_lib_rel = catdir( $arg, qw( lib perl5 ) );
    $local_lib     = rel2abs( $local_lib_rel );
  }

  ( $local_lib_root, $local_bin, $local_lib_rel, $local_lib )
}

1
