# NAME: Kibana 7.17.7
#
# DESCRIPTION: Kibana image.
#
# REQUIRED ENVS
# ELASTICSEARCH_[APP_ID]_HOST_ENDPOINT (ie. "http://10.0.4.3:9200")
# ENCRYPTION_KEY (ie. "jfuwyf74ksnchjf84hjfkd984jfbhsh48fjffdm34q", 32 characters minimum)
# HOST (ie. "10.0.4.3")
# PATH_DATA (ie. "/home/kibana/data/data")
# PORT (ie. "5601")
# SERVER_NAME (ie. "kibana.tds")
# SSL_ENABLED (true or false, must be true in production)
# SSL_CERT (ie "/path/to/cert.pem" only needed when SSL enabled, but must be "" otherwise)
# SSL_KEY (ie "/path/to/key" only needed when SSL enabled, but must be "" otherwise)
#
# OPTIONAL ENVS:
#
# OTHER:

FROM thedutchselection/debian:11.5
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg && \
  echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list && \
  apt-get update && \
  apt-get install -yq apt-transport-https && \
  useradd -m -u 5601 kibana && \
  apt-get install -yq kibana=7.17.7 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD files/kibana.yml /etc/kibana/
ADD files/scripts /usr/local/bin

RUN \
  chmod 660 /etc/kibana/kibana.yml && \
  chmod +x /usr/local/bin/run.sh && \
  chown kibana:kibana /etc/kibana && \
  chown root:kibana /etc/kibana/* && \
  chown kibana:kibana /usr/local/bin/*

USER kibana

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
