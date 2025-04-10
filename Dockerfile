FROM docker.io/library/perl:5.38.3-bookworm
WORKDIR /opt
ARG DISTVNAME
ADD ${DISTVNAME}.tar.gz .
WORKDIR ${DISTVNAME}
# upgrade cpm
#RUN cpm install --no-test --global App::cpm --show-build-log-on-failure
# install dependencies
RUN cpm install --no-test --with-configure --local-lib-contained local --show-build-log-on-failure
# configure
RUN perl Makefile.PL
# build
RUN make
ARG INST_ARCHLIB
ARG INST_LIB
ARG local_lib_rel
ARG INST_SCRIPT
ENV INST_ARCHLIB=${INST_ARCHLIB}
ENV INST_LIB=${INST_LIB}
ENV local_lib_rel=${local_lib_rel}
ENV INST_SCRIPT=${INST_SCRIPT}
CMD perl -I${INST_ARCHLIB} -I${INST_LIB} -I${local_lib_rel} ${INST_SCRIPT}/main.pl
