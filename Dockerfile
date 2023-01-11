# Use a LTS base image. Debian releases typically have 5 years of long-term support.
FROM debian:bullseye-slim

MAINTAINER Sven Gebauer <gebauers@fim.uni-passau.de>

ENV DEBIAN_FRONTEND noninteractive
ENV LANG="C.UTF-8"
ENV LC_ALL="C.UTF-8"
ENV HOME=/root

RUN apt-get update && apt-get --yes upgrade && apt-get --yes install \
  bison \
  cvs \
  flex \
  git \
  g++-9 \
  make \
  xml-twig-tools

ADD datasets ${HOME}/datasets
ADD patches ${HOME}/patches
ADD scripts ${HOME}/scripts
ADD xslt-templates ${HOME}/xslt-templates


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


# Download Xerces-c
WORKDIR ${HOME}
RUN git clone -b v1.6.0 https://github.com/apache/xerces-c.git xerces-c
# Explicitly checkout the commit-ID in case the tag has changed
# (Git clone -b only takes tags or branches, not commit-IDs)
RUN cd xerces-c && git reset --hard 272307b4d632b24c611d31c314fda8eb33471222

# Patch and build Xerces-c
ENV XERCESCROOT=${HOME}/xerces-c
WORKDIR ${XERCESCROOT}
RUN git apply ${HOME}/patches/xerces-c/*
RUN cd src && ./runConfigure -p linux -c gcc-9 -x g++-9 -P /usr/local/ && make && make install


# Download Xalan-c
WORKDIR ${HOME}
RUN git clone -b Xalan-C_1_3 https://github.com/apache/xalan-c.git xalan-c
# Explicitly checkout the commit-ID in case the tag has changed
RUN cd xalan-c && git reset --hard 238cdd552ef97c748a6a35bed11287ba0fe10d29

# Patch and build Xalan-c
ENV XALANCROOT=${HOME}/xalan-c
WORKDIR ${XALANCROOT}
RUN git apply ${HOME}/patches/xalan-c/*
RUN cd src && ./runConfigure -p linux -c gcc-9 -x g++-9 -P /usr/local/ && make
RUN cp lib/* /usr/local/lib/ && cp bin/* /usr/local/bin/
ENV LD_LIBRARY_PATH=/usr/local/lib


# Download input dataset
ADD https://dblp.org/xml/release/dblp-2023-01-03.xml.gz ${HOME}/datasets/dblp.xml.gz


# Clean up in order to reduce the final image size
RUN apt-get clean

WORKDIR ${HOME}
