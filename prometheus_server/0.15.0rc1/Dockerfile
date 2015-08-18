# NAME: Prometheus Server 0.15.0rc1
#
# DESCRIPTION: Prometheus server image.
#
# REQUIRED ENVS:
# DATA_DIRECTORY (ie. "/home/prometheus/data/")
# [HOST]_PUBLIC_IP (ie. "123.123.123.123")
# MEMORY_CHUNCKS (ie. "524288")
#
# OPTIONAL ENVS:
# ALERTMANAGER_HOST (ie. "10.0.0.1")
# ALERTMANAGER_PORT (ie. "9090")
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
  git clone https://github.com/prometheus/prometheus.git && \
  cd prometheus && \
  git checkout tags/0.15.0rc1 && \
  useradd -m -u 9090 prometheus

WORKDIR /go/src/github.com/prometheus/prometheus

RUN \
  make build && \
  cp prometheus /usr/local/bin/ && \
  mkdir -p /etc/prometheus && \
  make clean && \
  rm -rf /go

WORKDIR /home/prometheus

ADD files/prometheus.rules /etc/prometheus/prometheus.rules
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/prometheus/prometheus.rules && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R prometheus:prometheus /etc/prometheus && \
  chown -R prometheus:prometheus /usr/local/bin/*

EXPOSE 9090

USER prometheus

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
