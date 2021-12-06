# NAME: Environment for application Golf Tournament Planner
#
# DESCRIPTION:
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:

FROM thedutchselection/ruby:2.7.1
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  wget --no-check-certificate -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  wget --no-check-certificate -qO - https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
  wget --no-check-certificate -qO - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list && \
  apt-get update && \
  apt-get install -yq libgnutls30 && \
  apt-get install -yq curl && \
  curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
  apt-get install -yq nodejs && \
  apt-get install -yq libcairo2-dev && \
  apt-get install -yq libgirepository1.0-dev && \
  apt-get install -yq libpq-dev && \
  apt-get install -yq imagemagick && \
  apt-get install -yq libfontconfig && \
  apt-get install -yq libcurl4-gnutls-dev && \
  apt-get install -yq libpoppler-glib-dev && \
  apt-get install -yq mupdf-tools && \
  apt-get install -yq procps && \
  apt-get install -yq poppler-utils && \
  apt-get install -yq postgresql-client-12 && \
  apt-get install -yq yarn && \
  apt-get install -yq  google-chrome-stable && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  useradd -m -u 6666 appmaster

WORKDIR /tmp

WORKDIR /home/appmaster/application

ADD --chown=appmaster:appmaster files/gemfiles/Gemfile /home/appmaster/application/Gemfile
ADD --chown=appmaster:appmaster files/gemfiles/Gemfile.lock /home/appmaster/application/Gemfile.lock

RUN bundle install

ADD --chown=appmaster:appmaster files/packages/package.json /home/appmaster/application/package.json
ADD --chown=appmaster:appmaster files/packages/yarn.lock /home/appmaster/application/yarn.lock

USER appmaster

RUN \
  yarn install --network-timeout 1000000 --pure-lockfile

USER root
