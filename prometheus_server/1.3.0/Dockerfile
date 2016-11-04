# NAME: Prometheus Server 1.3.0
#
# DESCRIPTION: Prometheus server image.
#
# REQUIRED ENVS:
# DATA_DIRECTORY (ie. "/home/prometheus/data/")
# MEMORY_CHUNCKS (ie. "524288")
#
# OPTIONAL ENVS:
# ALERTMANAGER_HOST (ie. "10.0.0.1")
# ALERTMANAGER_PORT (ie. "9090")
# BLACKBOX_PROBE_URL_[TARGET_NAME] (ie. "123.123.123.123:9115/probe?target=google.com&module=http_2xx", replace all "=" for "%3D")
# ELASTICSEARCH_[HOST]_PUBLIC_IP (for the elasticsearch job ie. "123.123.123.123")
# HOST_[HOST]_PUBLIC_IP (for the hosts job ie. "123.123.123.123")
#
# OTHER:

FROM thedutchselection/alpine:3.4
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apk update && \
  apk add bash && \
  rm /var/cache/apk/*

ADD https://github.com/prometheus/prometheus/releases/download/v1.3.0/prometheus-1.3.0.linux-amd64.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar -xzf prometheus-1.3.0.linux-amd64.tar.gz && \
  mv prometheus-1.3.0.linux-amd64/prometheus /usr/local/bin/ && \
  mv prometheus-1.3.0.linux-amd64/promtool /usr/local/bin/ && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  adduser -D -u 9090 prometheus

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
