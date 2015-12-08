#!/bin/bash
set -e

echo "copy grafana-server file..."
cp -p /etc/default/grafana-server_template /etc/default/grafana-server


echo "copy grafana.ini file..."
cp -p /etc/grafana/grafana_template.ini /etc/grafana/grafana.ini

escaped_data_directory=${DATA_DIRECTORY//\//\\\/}

echo "set values to grafana-server file..."
sed -i "s/##data_directory##/$escaped_data_directory/g" /etc/default/grafana-server

echo "set values to grafana.ini file..."
sed -i "s/##database##/$DATABASE/g" /etc/grafana/grafana.ini
sed -i "s/##database_user##/$DATABASE_USER/g" /etc/grafana/grafana.ini
sed -i "s/##database_password##/$DATABASE_PASSWORD/g" /etc/grafana/grafana.ini
sed -i "s/##database_host##/$DATABASE_HOST/g" /etc/grafana/grafana.ini
sed -i "s/##database_port##/$DATABASE_PORT/g" /etc/grafana/grafana.ini
sed -i "s/##secret_key##/$SECRET_KEY/g" /etc/grafana/grafana.ini

echo "starting redis..."
exec /usr/local/bin/redis-server /etc/redis/redis.conf
