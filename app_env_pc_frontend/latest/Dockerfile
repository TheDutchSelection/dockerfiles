# NAME: Environment for application PC Frontend
#
# DESCRIPTION:
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:

FROM thedutchselection/nginx:1.15.12
LABEL org.opencontainers.image.authors="g.meijer@thedutchselection.com"

USER root

RUN \
  apk update && \
  apk add bash && \
  apk add nodejs && \
  apk add yarn && \
  mkdir /home/appmaster/application && \
  chown -R appmaster:appmaster /home/appmaster/application

WORKDIR /home/appmaster/application

ADD --chown=appmaster:appmaster files/packages/package.json /home/appmaster/application/package.json
ADD --chown=appmaster:appmaster files/packages/yarn.lock /home/appmaster/application/yarn.lock

USER appmaster

RUN yarn install --network-timeout 1000000 --pure-lockfile

USER root
