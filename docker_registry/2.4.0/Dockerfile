# NAME: Docker Registry 2.4.0
#
# DESCRIPTION: Docker Registry image.
#
# REQUIRED ENVS:
# DATA_DIRECTORY (ie. "/home/registry/data/")
# SECRET (ie. "abcdabcd1234")
#
# OPTIONAL ENVS:
# TLS_CERTIFICATE (ie. "/etc/ssl/custom/tdsservers.com.crt")
# TLS_KEY (ie. "/etc/ssl/private/tdsservers.com.key")
#
# OTHER:

FROM thedutchselection/go:1.6.2
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq librados-dev && \
  apt-get install -yq apache2-utils && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /go/src/github.com/docker

WORKDIR /go/src/github.com/docker

RUN \
  git clone https://github.com/docker/distribution.git && \
  cd distribution && \
  git checkout tags/v2.4.0 && \
  useradd -m -u 5000 registry

ENV DISTRIBUTION_DIR /go/src/github.com/docker/distribution

WORKDIR $DISTRIBUTION_DIR

RUN \
  make PREFIX=/go clean binaries && \
  cp /go/bin/* /usr/local/bin/ && \
  mkdir -p /etc/registry && \
  rm -rf /go

WORKDIR /home/registry

ADD files/config_template.yml /etc/registry/config_template.yml
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/registry/config_template.yml && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R registry:registry /etc/registry && \
  chown -R registry:registry /usr/local/bin/*

EXPOSE 5000

USER registry

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
