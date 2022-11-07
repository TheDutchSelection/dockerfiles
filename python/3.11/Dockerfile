# NAME: Python 3.11
#
# DESCRIPTION: Base for other images using Python.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE:

FROM thedutchselection/debian:11.5
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq build-essential && \
  apt-get install -yq zlib1g-dev && \
  apt-get install -yq libncurses5-dev && \
  apt-get install -yq libgdbm-dev && \
  apt-get install -yq libnss3-dev && \
  apt-get install -yq libssl-dev && \
  apt-get install -yq libreadline-dev && \
  apt-get install -yq libffi-dev && \
  apt-get install -yq libsqlite3-dev && \
  apt-get install -yq wget && \
  apt-get install -yq libbz2-dev

ADD https://www.python.org/ftp/python/3.11.0/Python-3.11.0.tgz /tmp/

WORKDIR /tmp

RUN \
  tar -xf Python-3.11.*.tgz && \
  cd Python-3.11.*/ && \
  ./configure --enable-optimizations && \
  make -j 4 && \
  make altinstall && \
  cd .. && \
  rm -rf Python-3.11.* && \
  rm -f Python-3.11.*.tgz

RUN \
  apt-get update && \
  apt-get install -yq python3-pip && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
