#!/bin/bash
set -e

echo "copy alertmanager.conf file..."
cp -p /etc/alertmanager/alertmanager_template.conf /etc/alertmanager/alertmanager.conf

echo "set values to alertmanager.conf file..."
sed -i "s/##prometheus_alertmanager_hosts_notification_email_address##/$HOSTS_NOTIFICATION_EMAIL_ADDRESS/g" /etc/alertmanager/alertmanager.conf
sed -i "s/##prometheus_alertmanager_pushover_application_token##/$PUSHOVER_APPLICATION_TOKEN/g" /etc/alertmanager/alertmanager.conf
sed -i "s/##prometheus_alertmanager_pushover_group_key##/$PUSHOVER_GROUP_KEY/g" /etc/alertmanager/alertmanager.conf

silence_file="$DATA_DIRECTORY""silences.json"

echo "starting prometheus alert manager..."
exec /usr/local/bin/alertmanager \
  -config.file=/etc/alertmanager/alertmanager.conf \
  -silences.file="$silence_file"
