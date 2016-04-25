#!/bin/bash
set -e

echo "copy config.yml file..."
cp -p /etc/registry/config_template.yml /etc/registry/config.yml

escaped_data_directory=${DATA_DIRECTORY//\//\\\/}
escaped_tls_certificate=${TLS_CERTIFICATE//\//\\\/}
escaped_tls_key=${TLS_KEY//\//\\\/}

echo "set values to config.yml file..."
sed -i "s/##data_directory##/$escaped_data_directory/g" /etc/registry/config.yml
sed -i "s/##secret##/$SECRET/g" /etc/registry/config.yml
sed -i "s/##tls_certificate##/$escaped_tls_certificate/g" /etc/registry/config.yml
sed -i "s/##tls_key##/$escaped_tls_key/g" /etc/registry/config.yml

echo "starting docker registry..."
exec /usr/local/bin/registry serve /etc/registry/config.yml