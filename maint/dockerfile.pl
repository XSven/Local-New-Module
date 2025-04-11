use strict;
use warnings;

our ( $Distvname, $Inst_archlib, $Inst_lib, $Local_lib_rel, $Exe_file );

print STDOUT <<"DOCKERFILE"
FROM docker.io/library/perl:5.38.3-bookworm
WORKDIR /opt
ADD ${Distvname}.tar.gz .
WORKDIR ${Distvname}
# upgrade cpm
RUN [ "cpm", "install", "--no-test", "--global", "App::cpm", "--show-build-log-on-failure" ]
# install dependencies
RUN [ "cpm", "install", "--no-test", "--with-configure", "--local-lib-contained", "local", "--show-build-log-on-failure" ]
# configure
RUN [ "perl", "Makefile.PL" ]
# build
RUN [ "make" ]
ENTRYPOINT [ "perl", "-I${Inst_archlib}", "-I${Inst_lib}", "-I${Local_lib_rel}", "${Exe_file}" ]
DOCKERFILE
