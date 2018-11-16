# NAME: Prometheus Server 2.5.0
#
# DESCRIPTION: Prometheus server image.
#
# REQUIRED ENVS:
# DATA_DIRECTORY (ie. "/home/prometheus/data/")
#
# OPTIONAL ENVS:
# ALERTMANAGER_HOST (ie. "10.0.0.1")
# ALERTMANAGER_PORT (ie. "9090")
# BLACKBOX_PROBE_URL_[TARGET_NAME] (ie. "123.123.123.123:9115/probe?target=google.com&module=http_2xx", replace all "=" for "%3D")
# HOST_[HOST]_PUBLIC_IP (for the hosts job ie. "123.123.123.123")
#
# OTHER:

FROM thedutchselection/alpine:3.8
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apk update && \
  apk add bash && \
  rm /var/cache/apk/*

ADD https://github.com/prometheus/prometheus/releases/download/v2.5.0/prometheus-2.5.0.linux-amd64.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar -xzf prometheus-2.5.0.linux-amd64.tar.gz && \
  mv prometheus-2.5.0.linux-amd64/prometheus /usr/local/bin/ && \
  mv prometheus-2.5.0.linux-amd64/promtool /usr/local/bin/ && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  adduser -D -u 9090 prometheus

WORKDIR /home/prometheus

ADD files/prometheus_template.rules.yml /etc/prometheus/prometheus_template.rules.yml
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/prometheus/prometheus_template.rules.yml && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R prometheus:prometheus /etc/prometheus && \
  chown -R prometheus:prometheus /usr/local/bin/*

EXPOSE 9090

USER prometheus

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
