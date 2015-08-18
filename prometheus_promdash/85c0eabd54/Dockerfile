# NAME: Prometheus Promdash 85c0eabd54
#
# DESCRIPTION: Prometheus Promdash.
#
# REQUIRED ENVS:
# DATABASE (ie. "prometheus_promdash_production")
# DATABASE_USER (ie. "prometheus_promdash")
# DATABASE_PASSWORD (ie. "abcdabcd")
# DATABASE_HOST (ie. "10.0.0.1")
# DATABASE_PORT (ie. "5432")
# RAILS_ENV (ie. "production")
#
# OPTIONAL ENVS:
#
# OTHER:

FROM thedutchselection/ruby:2.1.5
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq curl && \
  apt-get install -yq libpq-dev && \
  apt-get install -yq libcurl4-gnutls-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  useradd -m -u 6666 appmaster

WORKDIR /home/appmaster

RUN \
  git clone https://github.com/prometheus/promdash.git application && \
  cd application && \
  git checkout 391bb5ef25 && \
  cp config/database.yml.example config/database.yml

WORKDIR /home/appmaster/application

RUN bundle install --deployment --binstubs --without="development test mysql"

ADD files/scripts /usr/local/bin
ADD files/database.yml /home/appmaster/application/config/database.yml

RUN \
  chmod +x /usr/local/bin/run.sh && \
  chown -R appmaster:appmaster /home/appmaster

USER appmaster

ENV HOME /home/appmaster

WORKDIR /home/appmaster/application

EXPOSE 3000

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
