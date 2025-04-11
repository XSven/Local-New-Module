
# $Format:%D, %h$

use strict;
use warnings;

package MY;

use lib  ();
use subs qw( _which );

use Config                qw( %Config );
use File::Basename        qw( basename );
use File::Spec::Functions qw( catdir catfile rel2abs );
use Module::Loaded        qw( is_loaded );

my ( $local_lib_root, $local_bin, $local_lib_rel, $local_lib, $t_lib_rel, $prove_rc_file );

BEGIN {
  $local_lib_root = rel2abs( $ARGV[ 0 ] );

  $local_bin = catfile( $local_lib_root, qw( bin ) );

  $local_lib_rel = catdir( $ARGV[ 0 ], qw( lib perl5 ) );
  $local_lib     = rel2abs( $local_lib_rel );
  # need to prepend local library path to locate ExtUtils::MakeMaker::CPANfile
  # and other configure related modules
  lib->import( $local_lib );

  $t_lib_rel = catdir( qw( t lib ) );

  $prove_rc_file = rel2abs( catfile( qw( t .proverc ) ) )
}

# do not use "local" in the following line because then _which() will no see
# the modified PATH
if ( exists $ENV{ PATH } ) {
  $ENV{ PATH } = "$local_bin$Config{ path_sep }$ENV{ PATH }" ## no critic (RequireLocalizedPunctuationVars)
    unless grep { $local_bin eq $_ } split $Config{ path_sep }, $ENV{ PATH };
} else {
  $ENV{ PATH } = $local_bin; ## no critic (RequireLocalizedPunctuationVars)
}

# https://metacpan.org/pod/ExtUtils::MakeMaker#Overriding-MakeMaker-Methods

sub dist_basics {
  my ( $self ) = @_;

  my $inherited = $self->SUPER::dist_basics;
  $inherited =~ s/fullcheck$/'exit( scalar( map { \@\$\$_ } fullcheck() ) ? 1 : 0 )'/m;
  $inherited
}

sub dist_test {
  my ( $self ) = @_;

  my $inherited = $self->SUPER::dist_test;
  $inherited =~ s/^(disttest ?:.+)$/$1\n\t\$(CP) -R $local_lib_root \$(DISTVNAME)/m;
  $inherited
}

# https://metacpan.org/pod/ExtUtils::MM_Unix#test_via_harness-(override)
sub test_via_harness {
  my ( $self, $perl, $tests ) = @_;

  "\tPERL_DL_NONLAZY=1 $perl -Mlib=$local_lib "
    . rel2abs( catfile( qw( maint runtests.pl ) ) )
    . " \$(TEST_VERBOSE) \$(INST_ARCHLIB) \$(INST_LIB) $t_lib_rel $local_lib_rel $tests\n"
}

# https://metacpan.org/pod/ExtUtils::MM_Unix#test_via_script-(override)
sub test_via_script {
  my ( $self, $perl, $tests ) = @_;

  "\tPERL_DL_NONLAZY=1 $perl \"-I\$(INST_ARCHLIB)\" \"-I\$(INST_LIB)\" \"-I$t_lib_rel\" \"-I$local_lib_rel\" $tests\n"
}

# https://metacpan.org/pod/ExtUtils::MM_Any#postamble-(o)
sub postamble {
  my ( $self ) = @_;

  my $make_fragment = <<"MAKE_FRAGMENT";
export PATH := $ENV{ PATH }
undefine PERL5LIB

# runs the last modified test script
.PHONY: testlm
testlm:
	\$(NOECHO) \$(MAKE) TEST_FILES=\$\$(perl -e 'print STDOUT ( sort { -M \$\$a > -M \$\$b } glob( "\$\$ARGV[0]" ) )[0]' '\$(TEST_FILES)') test

# runs test scripts without a harness
# https://www.perlmonks.org/?node_id=1035633 (Directory Separator)
# apply catfile() based trailing slash ('/') directory separator hack
.PHONY: testn
testn: pure_all
	\$(NOECHO) for test_script in \$(TEST_FILES); do \\
	  \$(FULLPERLRUN) \$(foreach lib_rel,\$(INST_ARCHLIB) \$(INST_LIB) $t_lib_rel $local_lib_rel,-I${ \( catfile( rel2abs, '' ) ) }\$(lib_rel)) \$\${test_script};\\
	done
MAKE_FRAGMENT

  my $prove = _which 'prove';
  $make_fragment .= <<"MAKE_FRAGMENT" if $prove;

# runs test scripts through TAP::Harness (prove) instead of Test::Harness (ExtUtils::MakeMaker)
# https://metacpan.org/dist/Test-Harness/view/bin/prove#\@INC
.PHONY: testp
testp: pure_all
	\$(NOECHO) \$(FULLPERLRUN) -I$local_lib $prove\$(if \$(TEST_VERBOSE:0=), --verbose) --norc${ \( -f $prove_rc_file ? " --rc $prove_rc_file"  : '' ) } --blib -I$t_lib_rel -I$local_lib_rel -w --recurse --shuffle \$(TEST_FILES)
MAKE_FRAGMENT

  my $cover = _which 'cover';
  $make_fragment .= <<"MAKE_FRAGMENT" if $cover;

.PHONY: cover
cover:
	\$(NOECHO) $cover -test -ignore ${ \( basename( $local_lib_root ) ) } -report vim
MAKE_FRAGMENT

  my $podman = _which 'podman';
  $make_fragment .= <<"MAKE_FRAGMENT" if $podman;

.PHONY: buildimage
buildimage: distcheck dist
	\$(NOECHO) \$(FULLPERLRUN) -s ${ \( rel2abs( catfile( qw( maint dockerfile.pl ) ) ) ) } -Distvname=\$(DISTVNAME) -Inst_archlib=\$(INST_ARCHLIB) -Inst_lib=\$(INST_LIB) -Local_lib_rel=$local_lib_rel -Exe_file=\$(INST_SCRIPT)\$(DFSEP)\$(notdir \$(EXE_FILES)) | $podman image build --no-cache --env FULL_NAME=\"\$(FULL_NAME)\" --env EMAIL=\$(EMAIL) -f - .
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

1
