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

ENV GOLANG_VERSION 1.5.4
ENV GOLANG_DOWNLOAD_URL https://golang.org/dl/go$GOLANG_VERSION.linux-amd64.tar.gz
ENV GOLANG_DOWNLOAD_SHA256 a3358721210787dc1e06f5ea1460ae0564f22a0fbd91be9dcd947fb1d19b9560

WORKDIR /tmp

RUN \
  curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz && \
  echo "$GOLANG_DOWNLOAD_SHA256  golang.tar.gz" | sha256sum -c - && \
	tar -C /usr/local -xzf golang.tar.gz && \
	rm golang.tar.gz

ENV GOPATH /go
ENV PATH $GOPATH/bin:/usr/local/go/bin:$PATH

RUN \
  mkdir -p "$GOPATH/src" "$GOPATH/bin" && \
  chmod -R 777 "$GOPATH"

WORKDIR $GOPATH
