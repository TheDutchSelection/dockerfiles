# NAME: Environment for application Docs
#
# DESCRIPTION:
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:

FROM thedutchselection/nginx:1.15.5
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

USER root

RUN \
  apk update && \
  apk add py-pip && \
  pip install sphinx
