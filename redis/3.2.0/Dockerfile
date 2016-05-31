# NAME: Redis 3.2.0
#
# DESCRIPTION: Redis 3.2.0 image.
#
# REQUIRED ENVS:
# DATA_DIRECTORY (ie. "/home/redis/db")
#
# OPTIONAL ENVS:
# PASSWORD (ie. "abcdabcd1234")
#
# OTHER:

FROM thedutchselection/debian:8.4
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ADD http://download.redis.io/releases/redis-3.2.0.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar -xzf redis-3.2.0.tar.gz && \
  cd redis-3.2.0 && \
  make && \
  make install && \
  mkdir -p /etc/redis && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  useradd -m -u 6379 redis

ADD files/redis_template.conf /etc/redis/
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/redis/redis_template.conf && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R redis:redis /etc/redis && \
  chown redis:redis /usr/local/bin/*

EXPOSE 6379

USER redis

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
