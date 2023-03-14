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
  apt-get update && \
  apt-get install -yq libglib2.0-0 && \
  apt-get install -yq libatk1.0-0 && \
  apt-get install -yq libatk-bridge2.0-0 && \
  apt-get install -yq libcups2 && \
  apt-get install -yq libdrm2 && \
  apt-get install -yq libdbus-1-3 && \
  apt-get install -yq libatspi2.0-0 && \
  apt-get install -yq libxcomposite1 && \
  apt-get install -yq libxdamage1 && \
  apt-get install -yq libxfixes3 && \
  apt-get install -yq libxrandr2 && \
  apt-get install -yq libgbm1 && \
  apt-get install -yq libxkbcommon0 && \
  apt-get install -yq libpango-1.0-0 && \
  apt-get install -yq libcairo2 && \
  apt-get install -yq libasound2  && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  useradd -m -u 6666 appmaster && \
  mkdir /home/appmaster/application && \
  chown -R appmaster:appmaster /home/appmaster/application

WORKDIR /tmp

WORKDIR /home/appmaster/application

ADD --chown=appmaster:appmaster files/requirements/requirements.txt /home/appmaster/application/requirements.txt

RUN pip install -r requirements.txt

USER appmaster

RUN playwright install

USER root
