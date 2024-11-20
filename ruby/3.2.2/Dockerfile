# NAME: Ruby 3.2.2
#
# DESCRIPTION: Base for other images using Ruby.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE: docker run thedutchselection/ruby

FROM thedutchselection/debian:12.1
LABEL org.opencontainers.image.authors="g.meijer@thedutchselection.com"

RUN \
  apt-get update && \
  apt-get install -yq zlib1g-dev && \
  apt-get install -yq libssl-dev && \
  apt-get install -yq libreadline6-dev && \
  apt-get install -yq libyaml-dev && \
  apt-get install -yq libffi-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD http://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.2.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar -xzf ruby-3.2.2.tar.gz && \
  cd ruby-3.2.2 && \
  ./configure --with-readline-dir=/usr/lib/x86_64-linux-gnu && \
  make && \
  make install && \
  cd .. && \
  rm -rf ruby-3.2.2 && \
  rm -f ruby-3.2.2.tar.gz

RUN \
  gem install rubygems-update --no-document && \
  update_rubygems
