# NAME: Alpine 3.3
#
# DESCRIPTION: Base for other images using Alpine 3.3.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# OTHER:

FROM alpine:3.3
LABEL org.opencontainers.image.authors="g.meijer@thedutchselection.com"

ENV ALPINE_GLIBC_URL "https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64/"
ENV GLIBC_PKG "glibc-2.21-r2.apk"
ENV GLIBC_BIN_PKG "glibc-bin-2.21-r2.apk"

# https://github.com/gliderlabs/docker-alpine/issues/11
RUN \
  apk add --update -t deps wget ca-certificates && \
  cd /tmp && \
  wget ${ALPINE_GLIBC_URL}${GLIBC_PKG} ${ALPINE_GLIBC_URL}${GLIBC_BIN_PKG} && \
  apk add --allow-untrusted ${GLIBC_PKG} ${GLIBC_BIN_PKG} && \
  /usr/glibc/usr/bin/ldconfig /lib /usr/glibc/usr/lib && \
  echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
  apk del --purge deps && \
  rm /tmp/* /var/cache/apk/*