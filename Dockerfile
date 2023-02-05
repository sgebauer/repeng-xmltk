# Copyright 2023, Sven Gebauer <sven.gebauer@uni-passau.de>
# SPDX-License-Identifier: Apache-2.0

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
  latexmk \
  make \
  texlive-latex-extra \
  texlive-latex-recommended \
  xml-twig-tools

# texlive-fonts-extra is required by the ACM LaTeX template, but is very large.
# --no-install-recommends at least saves us 150MB of unnecessary dependencies.
RUN apt-get --yes install --no-install-recommends texlive-fonts-extra

ADD datasets ${HOME}/datasets
ADD patches ${HOME}/patches
ADD scripts ${HOME}/scripts
ADD xslt-templates ${HOME}/xslt-templates


# Download XMLTK
WORKDIR ${HOME}
# Since we don't have an exact date or XMLTK version for the original experiment, we use 2002-08-26, which is the
# oldest PDF build date of the paper we could find.
RUN cvs -z3 -d:pserver:anonymous@xmltk.cvs.sourceforge.net:/cvsroot/xmltk co -P -D 2002-08-26 xmltk
# In case the CVS repository breaks, comment out the line above, and enable to following two lines to use our git
# mirror instead:
#RUN git clone https://github.com/sgebauer/xmltk.git xmltk
#RUN cd xmltk && git reset --hard b50c38027b14cbd1f30cc07d2089f4646d1c7241

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

# Download report source files
WORKDIR ${HOME}
RUN git clone https://github.com/sgebauer/repeng-xmltk-report.git report
RUN cd report && git reset --hard feb4cada8c1059e5911235e21eb07f5d62352f66



# Clean up in order to reduce the final image size
RUN apt-get clean

WORKDIR ${HOME}
CMD ${HOME}/scripts/doall.sh
