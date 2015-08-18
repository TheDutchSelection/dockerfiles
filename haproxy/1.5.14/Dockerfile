# NAME: HAProxy 1.5.14
#
# DESCRIPTION: HAProxy image.
#
# REQUIRED ENVS:
# CRT_DIRECTORY (ie. /etc/ssl/domains/)
# [APP]_[APP_ID]_HOST_PUBLIC_IP (ie. "81.192.5.1")
# [APP]_[APP_ID]_HOST_PORT (ie. "1001")
# FRONTEND_[APP]_DOMAIN (ie. "backend.thedutchselection.com assets.thedutchselection.com")
#
# OPTIONAL ENVS:
# FRONTEND_[APP]_DOMAIN_FORCE_SSL (ie. "1")
# FRONTEND_[APP]_DOMAIN_REDIRECTS (ie. "www.backend.thedutchselection.com##!!backend.thedutchselection.com")
#
# OTHER:

FROM thedutchselection/debian:7.7
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq libpcre3-dev && \
  apt-get install -yq libssl-dev && \
  apt-get install -yq psmisc && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  useradd -m -u 8080 haproxy

ADD http://www.haproxy.org/download/1.5/src/haproxy-1.5.14.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar xvzf haproxy-1.5.14.tar.gz && \
  cd haproxy-1.5.14 && \
  make TARGET=linux2628 USE_PCRE=1 CPU=native USE_GETADDRINFO=1 USE_OPENSSL=1 && \
  make install && \
  mkdir -p /var/run/haproxy && \
  rm -f /tmp/haproxy-1.5.14.tar.gz && \
  rm -rf /tmp/haproxy-1.5.14

ADD files/scripts /usr/local/bin

RUN \
  mkdir -p /etc/haproxy && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R haproxy:haproxy /etc/haproxy && \
  chown -R haproxy:haproxy /var/run/haproxy && \
  chown haproxy:haproxy /usr/local/bin/*

EXPOSE 8080
EXPOSE 8443

USER haproxy

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
