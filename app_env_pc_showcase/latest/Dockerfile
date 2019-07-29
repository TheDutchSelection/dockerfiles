# NAME: Environment for application Beladvies.nl
#
# DESCRIPTION: Base for other the Beladvies.nl images. The gemfiles are a copy of the beladvies.nl
# apps actual gemfiles. When the files are updated in the beladvies.nl app, you can update them here.
# The more up to date they are, the faster the building process of the beladvies.nl app, but nothing
# will break when they are not up to date. The beladvies.nl dockerfile will always run bundle install
# on the latest files.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:

FROM thedutchselection/ruby:2.5.3
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  apt-get update && \
  apt-get install -yq curl && \
  curl -sL https://deb.nodesource.com/setup_8.x | bash - && \
  apt-get install -yq nodejs && \
  apt-get install -yq libpq-dev && \
  apt-get install -yq imagemagick && \
  apt-get install -yq libfontconfig && \
  apt-get install -yq libcurl4-gnutls-dev && \
  apt-get install -yq procps && \
  apt-get install -yq postgresql-client-9.6 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  useradd -m -u 6666 appmaster

WORKDIR /tmp

ADD https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-2.1.1-linux-x86_64.tar.bz2 /usr/local/share/

RUN \
  cd /usr/local/share && \
  tar -xvjf phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
  rm /usr/local/share/phantomjs-2.1.1-linux-x86_64.tar.bz2 && \
  ln -s /usr/local/share/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/local/bin/phantomjs && \
  ln -s /usr/local/share/phantomjs-2.1.1-linux-x86_64/bin/phantomjs /usr/bin/phantomjs

WORKDIR /tmp

ADD files/gemfiles/Gemfile /tmp/Gemfile
ADD files/gemfiles/Gemfile.lock /tmp/Gemfile.lock

RUN bundle install
