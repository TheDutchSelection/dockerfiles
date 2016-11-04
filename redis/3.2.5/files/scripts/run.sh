#!/bin/bash
set -e

echo "copy redis.conf file..."
cp -p /etc/redis/redis_template.conf /etc/redis/redis.conf

escaped_data_directory=${DATA_DIRECTORY//\//\\\/}

echo "set values to redis.conf file..."
sed -i "s/##data_directory##/$escaped_data_directory/g" /etc/redis/redis.conf
if [[ ! -z "$PASSWORD" ]]; then
  sed -i "s/##password##/requirepass $PASSWORD/g" /etc/redis/redis.conf
fi

echo "starting redis..."
exec /usr/local/bin/redis-server /etc/redis/redis.conf