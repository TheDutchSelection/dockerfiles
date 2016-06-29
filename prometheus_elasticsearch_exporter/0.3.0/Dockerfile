# NAME: Prometheus Elasticsearch Exporter 0.3.0
#
# DESCRIPTION: Prometheus Elasticsearch Exporter.
# https://github.com/ewr/elasticsearch_exporter
#
# REQUIRED ENVS:
# ELASTICSEARCH_URI (ie. "http://127.0.0.1:9200")
# WEB_LISTEN_PORT (ie. ":9107")
#
# OPTIONAL ENVS:
#
# OTHER:

FROM thedutchselection/alpine:3.2
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apk update && \
  apk add bash && \
  rm /var/cache/apk/*

ADD https://github.com/ewr/elasticsearch_exporter/releases/download/0.3.0/elasticsearch_exporter-0.3.0.linux-amd64.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar -xzf elasticsearch_exporter-0.3.0.linux-amd64.tar.gz && \
  mv elasticsearch_exporter /usr/local/bin/ && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /home

ADD files/scripts /usr/local/bin

RUN \
  chmod +x /usr/local/bin/run.sh

EXPOSE 9108

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
