# Use a LTS base image. Debian releases typically have 5 years of long-term support.
FROM debian:bullseye-slim

MAINTAINER Sven Gebauer <gebauers@fim.uni-passau.de>

ENV DEBIAN_FRONTEND noninteractive
ENV LANG="C.UTF-8"
ENV LC_ALL="C.UTF-8"

RUN apt-get update && apt-get --yes upgrade && apt-get --yes install \
  bison \
  cvs \
  flex \
  git \
  g++-9 \
  make


ENV HOME=/root
WORKDIR ${HOME}
ADD patches ${HOME}/patches


# Download XMLTK
WORKDIR ${HOME}
# Since we don't have an exact date or XMLTK version for the original experiment, we use 2002-08-26, which is the
# oldest PDF build date of the paper we could find.
RUN cvs -z3 -d:pserver:anonymous@xmltk.cvs.sourceforge.net:/cvsroot/xmltk co -P -D 2002-08-26 xmltk

# Patch and build XMLTK
ENV XMLTKROOT=${HOME}/xmltk
WORKDIR ${XMLTKROOT}
RUN git apply ${HOME}/patches/xmltk/*
RUN make SUBDIR='lib xpathDFA xsort' CC='gcc-9' CPP='g++-9' CXX='g++-9' BINDIR='/usr/local/bin' install

# Clean up in order to reduce the final image size
RUN apt-get clean

WORKDIR ${HOME}
