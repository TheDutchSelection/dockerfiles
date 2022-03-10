# NAME: Alpine 3.15.0
#
# DESCRIPTION: Base for other images using Alpine 3.8.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# OTHER:

FROM alpine:3.15.0
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN apk add --no-cache ca-certificates

RUN \
  apk add --update -t deps wget && \
  apk del --purge deps && \
  rm /var/cache/apk/*
