# NAME: HAProxy 3.3.10
#
# DESCRIPTION: HAProxy image.
#
# REQUIRED ENVS:
# [APP]_[APP_ID]_HOST_PUBLIC_IP (ie. "81.192.5.1", backend for app)
# [APP]_[APP_ID]_HOST_PORT (ie. "1001", backend for app)
# CRT_DIRECTORY (ie. /etc/ssl/domains/)
# DEFAULT_BACKEND (ie. [APP])
# FRONTEND_[APP]_WEB_DOMAIN (ie. "backend.thedutchselection.com assets.thedutchselection.com", frontend for app, not required for default backend)
#
# OPTIONAL ENVS:
# [APP]_[APP_ID]_HOST_HEALTH_CHECK_PATH (ie. "/health_check", health check path for app)
# [APP]_[APP_ID]_HOST_IS_BACKUP (ie. "1", marks host as backup backend)
# [APP]_[APP_ID]_HOST_MAXCONN (ie. "100", max connections to a backend)
# [APP]_[APP_ID]_HOST_USER_LIST (ie. "splash", should be the name of the user list for authentication, should all be lower case)
# [NAME]_USER_LIST_USER_NAME_[ID] (ie. "user1", a username for authentication)
# [NAME]_USER_LIST_USER_PASSWORD_[ID] (ie. "fIfds8#f", a password for user id for authentication)
# FRONTEND_[APP]_WEB_DOMAIN_FORCE_SSL (ie. "1", redirects to SSL)
# FRONTEND_[APP]_WEB_DOMAIN_REDIRECTS (ie. "www.backend.thedutchselection.com##!!backend.thedutchselection.com")
# FRONTEND_[APP]_INTERNAL_DOMAIN (ie. same as FRONTEND_[APP]_DOMAIN but for internal apps)
# FRONTEND_[APP]_INTERNAL_DOMAIN_FORCE_SSL (ie. "1", redirects to SSL)
# FRONTEND_[APP]_INTERNAL_DOMAIN_REDIRECTS (ie. "www.backend.thedutchselection.com##!!backend.thedutchselection.com")
#
# OTHER:

FROM thedutchselection/alpine:3.23.4
LABEL org.opencontainers.image.authors="g.meijer@thedutchselection.com"

RUN \
  apk update && \
  apk add bash && \
  apk add make && \
  apk add gcc && \
  apk add musl-dev && \
  apk add linux-headers && \
  apk add pcre2-dev && \
  apk add zlib-dev && \
  apk add openssl-dev && \
  rm /var/cache/apk/* && \
  adduser -D -u 8080 haproxy

ADD http://www.haproxy.org/download/3.3/src/haproxy-3.3.10.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar xvzf haproxy-3.3.10.tar.gz && \
  cd haproxy-3.3.10 && \
  make TARGET=linux-musl CPU=generic USE_PCRE2=1 USE_GETADDRINFO=1 USE_OPENSSL=1 USE_ZLIB=1 USE_PROMEX=1 && \
  make install && \
  mkdir -p /var/run/haproxy && \
  rm -f /tmp/haproxy-3.3.10.tar.gz && \
  rm -rf /tmp/haproxy-3.3.10

WORKDIR /home/haproxy

ADD files/scripts /usr/local/bin

RUN \
  mkdir -p /etc/haproxy && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R haproxy:haproxy /etc/haproxy && \
  chown -R haproxy:haproxy /var/run/haproxy && \
  chown haproxy:haproxy /usr/local/bin/*


EXPOSE 8036
EXPOSE 8080
EXPOSE 8443
EXPOSE 18080
EXPOSE 18443

USER haproxy

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
