#!/bin/bash
set -e

echo "copy alertmanager.yml file..."
cp -p /etc/alertmanager/alertmanager_template.yml /etc/alertmanager/alertmanager.yml

echo "set values to alertmanager.yml file..."
sed -i "s/##prometheus_alertmanager_hosts_notification_email_address##/$HOSTS_NOTIFICATION_EMAIL_ADDRESS/g" /etc/alertmanager/alertmanager.yml
sed -i "s/##prometheus_alertmanager_pushover_application_token##/$PUSHOVER_APPLICATION_TOKEN/g" /etc/alertmanager/alertmanager.yml
sed -i "s/##prometheus_alertmanager_pushover_group_key##/$PUSHOVER_GROUP_KEY/g" /etc/alertmanager/alertmanager.yml

echo "starting prometheus alert manager..."
exec /usr/local/bin/alertmanager \
  -config.file=/etc/alertmanager/alertmanager.yml \
  -storage.path="$DATA_DIRECTORY"
