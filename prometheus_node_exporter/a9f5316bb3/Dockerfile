# NAME: Prometheus Node Exporter a9f5316bb3
#
# DESCRIPTION: Prometheus Node Exporter.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# OTHER:

FROM thedutchselection/debian:8.1
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq vim-common && \
  apt-get install -yq mercurial && \
  apt-get install -yq libc6-dev && \
  apt-get install -yq make && \
  apt-get install -yq curl && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /go/src/github.com/prometheus

WORKDIR /go/src/github.com/prometheus

RUN \
  git clone https://github.com/prometheus/node_exporter.git && \
  cd node_exporter && \
  git checkout a9f5316bb3

WORKDIR /go/src/github.com/prometheus/node_exporter

RUN \
  make && \
  cp node_exporter /usr/local/bin/ && \
  mkdir -p /etc/prometheus_node_exporter && \
  make clean && \
  rm -rf /go

WORKDIR /home

ADD files/scripts /usr/local/bin

RUN \
  chmod +x /usr/local/bin/run.sh

EXPOSE 9100

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
