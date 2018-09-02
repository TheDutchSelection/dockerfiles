# NAME: Environment for application PC Inpage
#
# DESCRIPTION:
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:

FROM thedutchselection/nginx:1.14.0
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

USER root

RUN \
  apk update && \
  apk add bash && \
  apk add nodejs-npm && \
  apk add yarn

WORKDIR /tmp

ADD files/packages/package.json /tmp/package.json
ADD files/packages/yarn.lock /tmp/yarn.lock

RUN yarn install --network-timeout 1000000 --pure-lockfile
