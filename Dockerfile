# Use a LTS base image. Debian releases typically have 5 years of long-term support.
FROM debian:bullseye-slim

MAINTAINER Sven Gebauer <gebauers@fim.uni-passau.de>

ENV DEBIAN_FRONTEND noninteractive
ENV LANG="C.UTF-8"
ENV LC_ALL="C.UTF-8"

RUN apt-get update && apt-get --yes upgrade 

ENV HOME=/root

# Clean up in order to reduce the final image size
RUN apt-get clean

WORKDIR ${HOME}
