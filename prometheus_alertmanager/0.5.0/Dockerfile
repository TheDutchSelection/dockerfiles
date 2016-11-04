# NAME:  Prometheus Alertmanager 0.5.0
#
# DESCRIPTION: Prometheus Alertmanager.
#
# REQUIRED ENVS:
# PUSHOVER_APPLICATION_TOKEN (ie. "abcdabcd")
# PUSHOVER_GROUP_KEY (ie. "abcdabcd")
#
# OPTIONAL ENVS:
# DATA_DIRECTORY (ie. "/home/alertmanager/data/")
#
# OTHER:

FROM thedutchselection/alpine:3.4
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apk update && \
  apk add bash && \
  rm /var/cache/apk/*

ADD https://github.com/prometheus/alertmanager/releases/download/0.5.0/alertmanager-0.5.0.linux-amd64.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar -xzf alertmanager-0.5.0.linux-amd64.tar.gz && \
  mv alertmanager-0.5.0.linux-amd64/alertmanager /usr/local/bin/ && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  adduser -D -u 8100 alertmanager

WORKDIR /home/alertmanager

ADD files/alertmanager_template.yml /etc/alertmanager/alertmanager_template.yml
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/alertmanager/alertmanager_template.yml && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R alertmanager:alertmanager /etc/alertmanager && \
  chown -R alertmanager:alertmanager /usr/local/bin/*

EXPOSE 9093

USER alertmanager

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]

