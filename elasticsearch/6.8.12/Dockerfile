# NAME: Elasticsearch 6.8.12
#
# DESCRIPTION: Elasticsearch image.
#
# REQUIRED ENVS:
# CLUSTER_NAME (ie. "tds_nl")
# EXPECTED_NUMBER_OF_NODES (ie. "6")
# HOST (ie. "10.0.4.3")
# NODE_DATA (true or false)
# NODE_INGEST (true or false)
# NODE_NAME (ie. "doa3wrkprd004_master")
# NODE_MASTER (true or false)
# MAX_LOCAL_STORAGE_NODES (ie. "1")
# MINIMUM_MASTER_NODES (ie. "2")
# MINIMUM_NUMBER_OF_NODES (ie. "4")
# PATH_DATA (ie. "/home/elastic/data/data")
# PATH_LOGS (ie. "/home/elastic/data/logs")
# PATH_REPO (ie. "/home/elastic/data/backups")
# PUBLISH_HOST (ie. "10.0.4.3")
# TRANSPORT_PORT (ie. "9300")
# HTTP_PORT  (ie. "9200")
#
# OPTIONAL ENVS:
# ELASTICSEARCH_MASTER_[APP_ID]_HOST_PRIVATE_IP (ie. "10.0.4.3")
# ELASTICSEARCH_MASTER_[APP_ID]_HOST_PUBLIC_IP (ie. "10.0.4.3")
# ELASTICSEARCH_MASTER_[APP_ID]_HOST_PORT_PEER (ie. "9300")
# ES_JAVA_OPTS (ie. "-Xms2g -Xmx2g", to set heap size to 2GB, max heap size on a node is roughly 50% of all memory, but never larger than 30.5g)
#
# OTHER:

FROM thedutchselection/java:15
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ENV JAVA_HOME /usr/bin/

RUN \
  wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
  echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-6.x.list && \
  apt-get update && \
  apt-get install -yq apt-transport-https && \
  useradd -m -u 9200 elasticsearch && \
  apt-get install -yq elasticsearch=6.8.12 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD files/elasticsearch.yml /etc/elasticsearch/
ADD files/jvm.options /etc/elasticsearch/
ADD files/log4j2.properties /etc/elasticsearch/
ADD files/scripts /usr/local/bin

RUN \
  chmod 660 /etc/elasticsearch/elasticsearch.yml && \
  chmod 660 /etc/elasticsearch/jvm.options && \
  chmod 660 /etc/elasticsearch/log4j2.properties && \
  chmod +x /usr/local/bin/run.sh && \
  chown root:elasticsearch /etc/elasticsearch/* && \
  chown elasticsearch:elasticsearch /usr/local/bin/*

USER elasticsearch

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
