# NAME: AWS Cli
#
# DESCRIPTION: AWS Cli image.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
# AWS_ACCESS_KEY_ID (ie. "FDEDFD3FDFD3AKHR3")
# AWS_SECRET_ACCESS_KEY (ie. "yrthxdt45678oestwgsdf5es4trgd23")
# AWS_DEFAULT_REGION (ie. "eu-central-1")
#
# OTHER:

FROM thedutchselection/debian:8.1
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq curl && \
  apt-get install -yq python && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /tmp

RUN \
  curl -O https://bootstrap.pypa.io/get-pip.py && \
  python get-pip.py && \
  rm get-pip.py && \
  pip install awscli

ENTRYPOINT ["/bin/bash"]
