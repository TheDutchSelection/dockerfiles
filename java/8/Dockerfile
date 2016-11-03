# NAME: Java 8
#
# DESCRIPTION: Base for other images using Java.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE: docker run thedutchselection/java

FROM thedutchselection/debian:8.6
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq software-properties-common && \
  apt-get install -yq python-software-properties && \
  add-apt-repository ppa:webupd8team/java && \
  sed -i 's/jessie/trusty/g' /etc/apt/sources.list.d/webupd8team-java-jessie.list && \
  apt-get update && \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
  apt-get install -yq oracle-java8-installer && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*