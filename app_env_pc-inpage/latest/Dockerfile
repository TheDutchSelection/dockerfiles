# NAME: Environment for application PC Inpage
#
# DESCRIPTION:
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:

FROM thedutchselection/nginx:1.12.2
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

USER root

RUN \
  apk update && \
  apk add bash && \
  apk add nodejs-npm && \
  apk add yarn