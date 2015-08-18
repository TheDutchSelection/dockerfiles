# NAME: Ruby 2.2.0
#
# DESCRIPTION: Base for other images using Ruby.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE: docker run thedutchselection/ruby

FROM thedutchselection/debian:7.7
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq zlib1g-dev && \
  apt-get install -yq libssl-dev && \
  apt-get install -yq libreadline6-dev && \
  apt-get install -yq libyaml-dev && \
  apt-get install -yq libffi-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD http://cache.ruby-lang.org/pub/ruby/2.2/ruby-2.2.0.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar -xzf ruby-2.2.0.tar.gz && \
  cd ruby-2.2.0 && \
  ./configure --with-readline-dir=/usr/lib/x86_64-linux-gnu && \
  make && \
  make install && \
  cd .. && \
  rm -rf ruby-2.2.0 && \
  rm -f ruby-2.2.0.tar.gz

RUN \
  gem install rubygems-update --no-ri --no-rdoc && \
  update_rubygems && \
  gem install bundler --no-ri --no-rdoc