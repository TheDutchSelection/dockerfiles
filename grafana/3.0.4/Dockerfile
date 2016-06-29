# NAME: Grafana 3.0.4
#
# DESCRIPTION: Grafana.
#
# REQUIRED ENVS:
# DATA_DIRECTORY (ie. "/home/grafana/data/")
# DATABASE (ie. "grafana_production")
# DATABASE_USER (ie. "grafana")
# DATABASE_PASSWORD (ie. "abcdabcd")
# DATABASE_HOST (ie. "10.0.0.1")
# DATABASE_PORT (ie. "5432")
# SECRET_KEY (ie. "SW2YcwTIb9zpOOhoPsMm")
#
# OPTIONAL ENVS:
#
# OTHER:

FROM thedutchselection/debian:8.4
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq libfontconfig && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  useradd -m -u 3000 grafana

ADD https://grafanarel.s3.amazonaws.com/builds/grafana_3.0.4-1464167696_amd64.deb /tmp/

WORKDIR /tmp

RUN \
  dpkg -i grafana_3.0.4-1464167696_amd64.deb && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /home/grafana

ADD files/grafana-server_template /etc/default/
ADD files/grafana_template.ini /etc/grafana/
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/default/grafana-server_template && \
  chmod 640 /etc/grafana/grafana_template.ini && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R grafana:grafana /etc/default && \
  chown -R grafana:grafana /etc/grafana && \
  chown grafana:grafana /usr/local/bin/*

USER grafana

EXPOSE 3000

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
