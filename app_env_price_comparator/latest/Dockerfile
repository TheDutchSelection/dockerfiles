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

FROM thedutchselection/ruby:3.3.6
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  wget --no-check-certificate -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  wget --no-check-certificate -qO - https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
  echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list && \
  apt-get update && \
  apt-get install -yq libgnutls30 && \
  apt-get install -yq curl && \
  apt-get install -yq gnupg && \
  mkdir -p /etc/apt/keyrings && \
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg - && \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_18.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list && \
  apt-get install -yq nodejs && \
  apt-get install -yq libpq-dev && \
  apt-get install -yq git && \
  apt-get install -yq imagemagick && \
  apt-get install -yq libfontconfig && \
  apt-get install -yq libcurl4-gnutls-dev && \
  apt-get install -yq procps && \
  apt-get install -yq autoconf && \
  apt-get install -yq automake && \
  apt-get install -yq libtool && \
  apt-get install -yq pkg-config && \
  apt-get install -yq postgresql-client-12 && \
  apt-get install -yq yarn && \
  useradd -m -u 6666 appmaster && \
  mkdir /home/appmaster/application && \
  chown -R appmaster:appmaster /home/appmaster/application

WORKDIR /tmp

RUN \
    git clone https://github.com/openvenues/libpostal && \
    cd libpostal && \
    ./bootstrap.sh && \
    ./configure  && \
    make && \
    make install

WORKDIR /home/appmaster/application

ADD --chown=appmaster:appmaster files/gemfiles/Gemfile /home/appmaster/application/Gemfile
ADD --chown=appmaster:appmaster files/gemfiles/Gemfile.lock /home/appmaster/application/Gemfile.lock

RUN bundle install
