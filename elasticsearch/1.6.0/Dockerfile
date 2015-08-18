# NAME: Elasticsearch 1.6.0
#
# DESCRIPTION: Elasticsearch image.
#
# REQUIRED ENVS:
# CLUSTER_NAME (ie. "tds_nl")
# NODE_NAME (ie. "doa3wrkprd004_master")
# NODE_MASTER (true or false)
# NODE_DATA (true or false)
# MAX_LOCAL_STORAGE_NODES (ie. "1")
# NUMBER_OF_SHARDS (ie. "5")
# NUMBER_OF_REPLICAS (ie. "1")
# PATH_DATA (ie. "/home/elastic/data/data")
# PATH_WORK (ie. "/home/elastic/data/work")
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
#
# OTHER:
# To upgrade nodes, first disable shard reallocation:
# curl -XPUT localhost:9200/_cluster/settings -d '{"transient":{"cluster.routing.allocation.enable":"none"}}'
# Then shutdown node, upgrade, confirm it joins the cluster, reenable shard reallocation:
# curl -XPUT localhost:9200/_cluster/settings -d '{"transient":{"cluster.routing.allocation.enable":"all"}}'
# Observe that all shards are properly allocated on all nodes. Balancing may take some time. Repeat this process for all
# remaining nodes.

FROM thedutchselection/java:8
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ADD https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.6.0.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar xvzf elasticsearch-1.6.0.tar.gz && \
  mv /tmp/elasticsearch-1.6.0 /usr/local/bin/elasticsearch && \
  useradd -m -u 9200 elastic

ADD files/elasticsearch.yml /usr/local/bin/elasticsearch/config/
ADD files/logging.yml /usr/local/bin/elasticsearch/config/
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /usr/local/bin/elasticsearch/config/elasticsearch.yml && \
  chmod 640 /usr/local/bin/elasticsearch/config/logging.yml && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R elastic:elastic /usr/local/bin/elasticsearch && \
  chown elastic:elastic /usr/local/bin/*

USER elastic

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
