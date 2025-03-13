let $PERL5LIB = join( filter( map ( [ 't/lib', 'lib', 'local/lib/perl5' ], { idx, val -> getcwd() . '/' . val } ), { idx, val -> isdirectory( val ) } ), ':' )  . ':' . $PERL5LIB
let $PATH = join( filter( map ( [ 'local/bin' ], { idx, val -> getcwd() . '/' . val } ), { idx, val -> isdirectory( val ) } ), ':' )  . ':' . $PATH
map <F6> :!ctags --totals=yes --append=no --kinds-perl=+d --extras=+f --extras=+q --recurse=yes --sort=yes --exclude='.git' --exclude='blib' --exclude='*~' --languages=Perl --langmap=Perl:+.t<CR>
let &rtp = fnamemodify( getcwd(), ':p' ) . '.vim,' . &rtp
