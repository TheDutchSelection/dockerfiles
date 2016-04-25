# NAME: Go 1.5.2
#
# DESCRIPTION: Base for other images using Go.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# OTHER:

FROM thedutchselection/debian:8.4
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq curl && \
  apt-get install -yq g++ && \
  apt-get install -yq gcc && \
  apt-get install -yq libc6-dev && \
  apt-get install -yq make && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV GOLANG_VERSION 1.5.2

WORKDIR /tmp

RUN \
  curl -fsSL https://golang.org/dl/go$GOLANG_VERSION.src.tar.gz -o golang.tar.gz && \
  tar -C /usr/local -xzf golang.tar.gz && \
  rm golang.tar.gz

ENV PATH /usr/src/go/bin:$PATH

RUN mkdir -p /go/src /go/bin && chmod -R 777 /go

ENV GOPATH /go
ENV PATH /go/bin:/usr/local/go/bin:$PATH

WORKDIR $GOPATH
