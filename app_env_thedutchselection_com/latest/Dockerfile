# NAME: Environment for application Thedutchselection.com
#
# DESCRIPTION: Base for other the Thedutchselection.com images. The gemfiles are a copy of the thedutchselection.com
# apps actual gemfiles. When the files are updated in the thedutchselection.com app, you can update them here.
# The more up to date they are, the faster the building process of the beladvies.nl app, but nothing
# will break when they are not up to date. The Thedutchselection.com dockerfile will always run bundle install
# on the latest files.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:

FROM thedutchselection/ruby:2.2.2
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq curl && \
  curl -sL https://deb.nodesource.com/setup | bash - && \
  apt-get install -yq nodejs && \
  apt-get install -yq libpq-dev && \
  apt-get install -yq libcurl4-gnutls-dev && \
  apt-get install -yq procps && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  useradd -m -u 6666 appmaster

WORKDIR /tmp
ADD files/gemfiles/Gemfile /tmp/Gemfile
ADD files/gemfiles/Gemfile.lock /tmp/Gemfile.lock

RUN bundle install