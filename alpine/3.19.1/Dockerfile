# NAME: Alpine 3.19.1
#
# DESCRIPTION: Base for other images using Alpine 3.19.1
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# OTHER:

FROM alpine:3.19.1
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN apk add --no-cache ca-certificates

RUN \
  apk add --update -t deps wget && \
  apk del --purge deps && \
  rm /var/cache/apk/*
