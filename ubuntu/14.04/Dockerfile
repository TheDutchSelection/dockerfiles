# NAME: Ubuntu 14.04
#
# DESCRIPTION: Base for other images using Ubuntu 14.04.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE: docker run thedutchselection/ubuntu

FROM ubuntu:14.04
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN locale-gen en_US.UTF-8

ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.utf8
ENV LANGUAGE en_US.utf8
ENV LC_ALL en_US.utf8

RUN \
  echo 'LANG=en_US.utf8' > /etc/default/locale && \
  dpkg-reconfigure locales && \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -yq upgrade && \
  apt-get install -yq build-essential && \
  apt-get install -yq wget && \
  apt-get install -yq git && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*