#!/bin/bash
set -e

escaped_data_directory=${DATA_DIRECTORY//\//\\\/}

echo "set values to redis.conf file..."
sed -i "s/##data_directory##/$escaped_data_directory/g" /etc/redis/redis.conf
if [[ ! -z "$PASSWORD" ]]; then
  sed -i "s/##password##/requirepass $PASSWORD/g" /etc/redis/redis.conf
fi
if [[ ! -z "$MAX_MEMORY_IN_BYTES" ]]; then
  sed -i "s/##max_memory##/maxmemory $MAX_MEMORY_IN_BYTES/g" /etc/redis/redis.conf
fi

echo "starting redis..."
exec /usr/local/bin/redis-server /etc/redis/redis.conf