# NAME: Elasticsearch 7.17.7
#
# DESCRIPTION: Elasticsearch image.
#
# REQUIRED ENVS:
# CLUSTER_NAME (ie. "tds_nl")
# DISCOVERY_TYPE ("single-node" or empty)
# HOST (ie. "10.0.4.3")
# NODE_NAME (ie. "doa3wrkprd004_master")
# NODE_ROLES (ie. "[master]" or "[data, ingest]")
# PATH_DATA (ie. "/home/elastic/data/data")
# PATH_LOGS (ie. "/home/elastic/data/logs")
# PATH_REPO (ie. "/home/elastic/data/backups")
# PUBLISH_HOST (ie. "10.0.4.3")
# RECOVERY_AFTER_TIME (ie. "5m")
# REQUIRED_EXPLICIT_DESTRUCTIVE_NAMES (ie. true, false for testing)
# SECURITY_TRANSPORT_SSL_ENABLED (true or false, must be true in production)
# SUPERUSER_USERNAME (ie. "superuser")
# SUPERUSER_PASSWORD (ie. "abcdabcd1234")
# TRANSPORT_PORT (ie. "9300")
# HTTP_PORT  (ie. "9200")
#
# OPTIONAL ENVS:
# ELASTICSEARCH_MASTER_[APP_ID]_HOST_PRIVATE_IP (ie. "10.0.4.3")
# ELASTICSEARCH_MASTER_[APP_ID]_HOST_PUBLIC_IP (ie. "10.0.4.3")
# ELASTICSEARCH_MASTER_[APP_ID]_HOST_PORT_PEER (ie. "9300")
# ELASTICSEARCH_MASTER_[APP_ID]_NODE_NAME (ie. "doa3wrkprd004_master")
# ES_JAVA_OPTS (ie. "-Xms2g -Xmx2g", to set heap size to 2GB, max heap size on a node is roughly 50% of all memory, but never larger than 30.5g)
# KIBANA_SYSTEM_USER_USERNAME (ie. "kibana_su")
# KIBANA_SYSTEM_USER_PASSWORD (ie. "abcdabcd1234")
# SECURITY_TRANSPORT_SSL_KEYSTORE_PATH (ie "/path/to/elastic-certificates.p12" only needed when SSL enabled)
# SECURITY_TRANSPORT_SSL_TRUSTSTORE_PATH (ie "/path/to/elastic-certificates.p12" only needed when SSL enabled)
# TRANSPORT_PRIVATE_KEY_PASSWORD (ie. "abcdabcd", only when SECURITY_TRANSPORT_SSL_ENABLED=true)
#
# OTHER:
# The ssl transport layer is encrypted using the following instructions
# https://www.elastic.co/guide/en/elasticsearch/reference/current/security-basic-setup.html

FROM thedutchselection/java:17
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ENV ES_JAVA_HOME /usr/lib/jvm/jdk-17

RUN \
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
  echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list && \
  apt-get update && \
  apt-get install -yq apt-transport-https && \
  useradd -m -u 9200 elasticsearch && \
  apt-get install -yq elasticsearch=7.17.7 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD files/elasticsearch.yml /etc/elasticsearch/
ADD files/elastic-certificates.p12 /etc/elasticsearch/
ADD files/scripts /usr/local/bin

RUN \
  chmod 660 /etc/elasticsearch/elasticsearch.yml && \
  chmod 660 /etc/elasticsearch/elastic-certificates.p12 && \
  chmod +x /usr/local/bin/run.sh && \
  chown elasticsearch:elasticsearch /etc/elasticsearch && \
  chown root:elasticsearch /etc/elasticsearch/* && \
  chown elasticsearch:elasticsearch /usr/local/bin/*

ENV SECURITY_TRANSPORT_SSL_KEYSTORE_PATH=""
ENV SECURITY_TRANSPORT_SSL_TRUSTSTORE_PATH=""

USER elasticsearch

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
