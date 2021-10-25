# NAME: Redis 6.2.6
#
# DESCRIPTION:
#
# REQUIRED ENVS:
# DATA_DIRECTORY (ie. "/home/redis/db")
#
# OPTIONAL ENVS:
# PASSWORD (ie. "abcdabcd1234")
# MAX_MEMORY_IN_BYTES (ie. "1073741824", best is to keep 10% of memory for overhead)
#
# OTHER:

FROM thedutchselection/debian:11.0
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ADD https://download.redis.io/releases/redis-6.2.6.tar.gz /tmp/

WORKDIR /tmp

RUN \
  apt-get update && \
  apt-get install -yq pkg-config && \
  tar -xzf redis-6.2.6.tar.gz && \
  cd redis-6.2.6 && \
  make && \
  make install && \
  mkdir -p /etc/redis && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  useradd -m -u 6379 redis

ADD files/redis.conf /etc/redis/
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/redis/redis.conf && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R redis:redis /etc/redis && \
  chown redis:redis /usr/local/bin/*

EXPOSE 6379

USER redis

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
