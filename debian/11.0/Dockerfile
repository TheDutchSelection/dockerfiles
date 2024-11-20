# NAME: Debian 11.0
#
# DESCRIPTION: Base for other images using Debian 11.0
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE: docker run thedutchselection/debian

FROM debian:11.0
LABEL org.opencontainers.image.authors="g.meijer@thedutchselection.com"

ENV DEBIAN_FRONTEND noninteractive

RUN \
  apt-get -yq update && \
  apt-get -yq install apt-utils && \
  apt-get -yq upgrade && \
  apt-get install -yq locales && \
  apt-get install -yq build-essential && \
  apt-get -yq install wget && \
  apt-get -yq install git && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  dpkg-reconfigure locales && \
  echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen && \
  locale-gen

ENV LANG en_US.utf8
ENV LANGUAGE en_US.utf8
ENV LC_ALL en_US.utf8