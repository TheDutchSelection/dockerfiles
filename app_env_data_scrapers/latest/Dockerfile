# NAME: Environment for application Data Scrapers
#
# DESCRIPTION:
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:

FROM thedutchselection/python:3.11
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  useradd -m -u 6666 appmaster && \
  mkdir /home/appmaster/application && \
  chown -R appmaster:appmaster /home/appmaster/application

WORKDIR /tmp

WORKDIR /home/appmaster/application

ADD --chown=appmaster:appmaster files/requirements/requirements.txt /home/appmaster/application/requirements.txt

RUN pip install -r requirements.txt

RUN playwright install

USER root
