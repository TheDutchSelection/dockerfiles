# NAME: Environment for application Price Comparator
#
# DESCRIPTION: Base for other the Price Comparator images. The gemfiles are a copy of the price comparator
# apps actual gemfiles. When the files are updated in the price comparator app, you can update them here.
# The more up to date they are, the faster the building process of the price comparator app, but nothing
# will break when they are not up to date. The price comparator dockerfile will always run bundle install
# on the latest files.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:

FROM thedutchselection/ruby:2.7.1
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  wget --quiet -O - https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  apt-get install -yq curl && \
  curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get install -yq nodejs && \
  apt-get install -yq libpq-dev && \
  apt-get install -yq imagemagick && \
  apt-get install -yq libfontconfig && \
  apt-get install -yq libcurl4-gnutls-dev && \
  apt-get install -yq procps && \
  apt-get install -yq postgresql-client-12 && \
  apt-get install -yq yarn && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  useradd -m -u 6666 appmaster

RUN \
  wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && \
  apt update && \
  apt install -yq google-chrome-stable && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /tmp

ADD files/gemfiles/Gemfile /tmp/Gemfile
ADD files/gemfiles/Gemfile.lock /tmp/Gemfile.lock

RUN bundle install

ADD files/packages/package.json /tmp/package.json
ADD files/packages/yarn.lock /tmp/yarn.lock

USER appmaster

RUN \
  yarn install --network-timeout 1000000 --pure-lockfile

USER root
