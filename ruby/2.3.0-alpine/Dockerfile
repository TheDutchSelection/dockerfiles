# NAME: Ruby 2.3.0
#
# DESCRIPTION: Base for other images using Ruby.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE: docker run thedutchselection/ruby

FROM thedutchselection/alpine:3.3
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apk update && \
  apk add linux-headers && \
  apk add bash && \
  apk add make && \
  apk add pcre-dev && \
  apk add zlib-dev && \
  apk add musl && \
  apk add libedit && \
  apk add yaml && \
  apk add gmp && \
  apk add libffi && \
  apk add readline-dev && \
  apk add openssl-dev && \
  apk add gdbm-dev && \
  apk add g++ && \
  rm /var/cache/apk/*

ADD http://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.0.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar -xzf ruby-2.3.0.tar.gz && \
  cd ruby-2.3.0 && \
  ./configure && \
  make && \
  make install && \
  cd .. && \
  rm -rf ruby-2.3.0 && \
  rm -f ruby-2.3.0.tar.gz

RUN \
  gem install rubygems-update --no-ri --no-rdoc && \
  update_rubygems && \
  gem install bundler --no-ri --no-rdoc
