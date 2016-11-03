# NAME: Alpine 3.4
#
# DESCRIPTION: Base for other images using Alpine 3.4.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# OTHER:

FROM alpine:3.4
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ENV ALPINE_GLIBC_URL "https://circle-artifacts.com/gh/andyshinn/alpine-pkg-glibc/6/artifacts/0/home/ubuntu/alpine-pkg-glibc/packages/x86_64/"
ENV GLIBC_PKG "glibc-2.21-r2.apk"
ENV GLIBC_BIN_PKG "glibc-bin-2.21-r2.apk"

# https://github.com/gliderlabs/docker-alpine/issues/11
RUN \
  apk add --update -t deps wget ca-certificates && \
  apk del --purge deps && \
  rm /var/cache/apk/*