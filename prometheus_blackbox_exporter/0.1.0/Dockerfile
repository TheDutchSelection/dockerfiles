# NAME: Prometheus Blackbox Exporter 0.1.0
#
# DESCRIPTION: Prometheus Blackbox Exporter.
#
# REQUIRED ENVS:
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

ADD https://github.com/prometheus/blackbox_exporter/releases/download/0.1.0/blackbox_exporter-0.1.0.linux-amd64.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar -xzf blackbox_exporter-0.1.0.linux-amd64.tar.gz && \
  mv blackbox_exporter /usr/local/bin/ && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /home

ADD files/blackbox.yml /etc/blackbox_exporter/blackbox.yml
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/blackbox_exporter/blackbox.yml && \
  chmod +x /usr/local/bin/run.sh

EXPOSE 9115

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
