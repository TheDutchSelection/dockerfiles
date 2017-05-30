# NAME: Environment for application PC Inpage
#
# DESCRIPTION:
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:

FROM thedutchselection/debian:8.7
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq curl && \
  curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
  curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  apt-get install -yq nodejs && \
  apt-get install -yq yarn && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  useradd -m -u 6666 appmaster

WORKDIR /tmp

USER appmaster

ADD files/package/package.json /tmp/package.json
ADD files/package/yarn.lock /tmp/yarn.lock

RUN \
  yarn && \
  mv node_modules /home/appmaster/
