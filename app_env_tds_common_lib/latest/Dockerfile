# NAME: Environment for the TDS Common Lib
#
# DESCRIPTION: Base for other the TDS Common Lib images.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:

FROM thedutchselection/ruby:2.7.1
LABEL org.opencontainers.image.authors="g.meijer@thedutchselection.com"

RUN \
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  wget --quiet -O - https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  apt-get install -yq curl && \
  curl -sL https://deb.nodesource.com/setup_14.x | bash - && \
  apt-get install -yq nodejs && \
  apt-get install -yq libpq-dev && \
  apt-get install -yq imagemagick && \
  apt-get install -yq libfontconfig && \
  apt-get install -yq libcurl4-gnutls-dev && \
  apt-get install -yq procps && \
  apt-get install -yq postgresql-client-12 && \
  apt-get install -yq yarn && \
  useradd -m -u 6666 appmaster && \
  mkdir -p /home/appmaster/application/lib/tds_common_lib && \
  chown -R appmaster:appmaster /home/appmaster/application

WORKDIR /tmp

RUN \
  wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
  apt install -yq ./google-chrome-stable_current_amd64.deb && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /home/appmaster/application

ADD --chown=appmaster:appmaster files/gemfiles/Gemfile /home/appmaster/application/Gemfile
ADD --chown=appmaster:appmaster files/gemfiles/tds_common_lib.gemspec /home/appmaster/application/tds_common_lib.gemspec
ADD --chown=appmaster:appmaster files/gemfiles/version.rb /home/appmaster/application/lib/tds_common_lib/version.rb
ADD --chown=appmaster:appmaster files/gemfiles/Gemfile.lock /home/appmaster/application/Gemfile.lock

RUN bundle install

ADD --chown=appmaster:appmaster files/packages/package.json /home/appmaster/application/package.json
ADD --chown=appmaster:appmaster files/packages/yarn.lock /home/appmaster/application/yarn.lock

USER appmaster

RUN \
  yarn install --network-timeout 1000000 --pure-lockfile

USER root
