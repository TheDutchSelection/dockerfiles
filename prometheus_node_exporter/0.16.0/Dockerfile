# NAME: Prometheus Node Exporter 0.16.0
#
# DESCRIPTION: Prometheus Node Exporter.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# OTHER:

FROM thedutchselection/alpine:3.8
LABEL org.opencontainers.image.authors="g.meijer@thedutchselection.com"

RUN \
  apk update && \
  apk add bash && \
  rm /var/cache/apk/*

ADD https://github.com/prometheus/node_exporter/releases/download/v0.16.0/node_exporter-0.16.0.linux-amd64.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar -xzf node_exporter-0.16.0.linux-amd64.tar.gz && \
  mv node_exporter-0.16.0.linux-amd64/node_exporter /usr/local/bin/ && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /home

ADD files/scripts /usr/local/bin

RUN \
  chmod +x /usr/local/bin/run.sh

EXPOSE 9100

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
