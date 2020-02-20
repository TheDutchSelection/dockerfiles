# NAME: Bitcoin Core 0.19.0.1
#
# DESCRIPTION: Bitcoin Core.
#
# REQUIRED ENVS:
# DATA_PATH (ie. "/home/bitcoin/data")
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE: docker run thedutchselection/bitcoin_core

FROM thedutchselection/debian:10.2
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq curl && \
  apt-get install -yq gnupg && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  useradd -m -u 8332 bitcoin

ENV BITCOIN_VERSION=0.19.0.1
ENV PATH=/opt/bitcoin-${BITCOIN_VERSION}/bin:$PATH

RUN \
  for key in \
    01EA5486DE18A882D4C2684590C8019E36C2E964 \
  ; do \
      gpg --batch --keyserver keyserver.ubuntu.com --recv-keys "$key" || \
      gpg --batch --keyserver pgp.mit.edu --recv-keys "$key" || \
      gpg --batch --keyserver keyserver.pgp.com --recv-keys "$key" || \
      gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" || \
      gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" ; \
    done && \
  curl -SLO https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc && \
  curl -SLO https://bitcoin.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz && \
  gpg --verify SHA256SUMS.asc && \
  grep " bitcoin-${BITCOIN_VERSION}-x86_64-linux-gnu.tar.gz\$" SHA256SUMS.asc | sha256sum -c - && \
  tar -xzf *.tar.gz -C /opt && \
  rm *.tar.gz *.asc

ADD files/scripts /usr/local/bin

RUN \
  chown bitcoin:bitcoin /usr/local/bin/*

EXPOSE 8332 8333

USER bitcoin

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
