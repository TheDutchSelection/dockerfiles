# NAME:  Prometheus Alertmanager d91ac2ef11
#
# DESCRIPTION: Prometheus Alertmanager.
#
# REQUIRED ENVS:
# HOSTS_NOTIFICATION_EMAIL_ADDRESS (ie. "a@b.com")
# PUSHOVER_APPLICATION_TOKEN (ie. "abcdabcd")
# PUSHOVER_GROUP_KEY (ie. "abcdabcd")
#
# OPTIONAL ENVS:
# DATA_DIRECTORY (ie. "/home/alertmanager/data/")
#
# OTHER:

FROM thedutchselection/debian:8.1
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq vim-common && \
  apt-get install -yq mercurial && \
  apt-get install -yq libc6-dev && \
  apt-get install -yq curl && \
  apt-get install -yq make && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /go/src/github.com/prometheus

WORKDIR /go/src/github.com/prometheus

RUN \
  git clone https://github.com/prometheus/alertmanager.git && \
  cd alertmanager && \
  git checkout d91ac2ef11 && \
  useradd -m -u 8100 alertmanager

WORKDIR /go/src/github.com/prometheus/alertmanager

RUN \
  make && \
  cp alertmanager /usr/local/bin/ && \
  mkdir -p /etc/alertmanager && \
  make clean && \
  rm -rf /go

WORKDIR /home/alertmanager

ADD files/alertmanager_template.conf /etc/alertmanager/alertmanager_template.conf
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/alertmanager/alertmanager_template.conf && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R alertmanager:alertmanager /etc/alertmanager && \
  chown -R alertmanager:alertmanager /usr/local/bin/*

USER alertmanager

EXPOSE 9093

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
