# NAME: PhantomJS 2.0
#
# DESCRIPTION: PhantomJS image.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# OTHER:
# This image is intended to build PhantomJS. Best is to build it with the kernel that you need to use it on. After
# the build is completed you can get it with "docker cp". The executable is in /tmp/phantomjs/bin.

FROM thedutchselection/debian:8.1
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq curl && \
  apt-get install -yq g++ && \
  apt-get install -yq flex && \
  apt-get install -yq bison && \
  apt-get install -yq gperf && \
  apt-get install -yq ruby && \
  apt-get install -yq perl && \
  apt-get install -yq libsqlite3-dev && \
  apt-get install -yq libfontconfig1-dev && \
  apt-get install -yq libicu-dev && \
  apt-get install -yq libfreetype6 && \
  apt-get install -yq libssl-dev && \
  apt-get install -yq libpng-dev && \
  apt-get install -yq libjpeg-dev && \
  apt-get install -yq python && \
  apt-get install -yq libx11-dev && \
  apt-get install -yq libxext-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /opt/jenkins

WORKDIR /tmp

ADD files/scripts /usr/local/bin

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
