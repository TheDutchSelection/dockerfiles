#!/bin/bash
set -e

echo "starting prometheus blackbox exporter..."
exec /usr/local/bin/blackbox_exporter --config.file="/etc/blackbox_exporter/blackbox.yml" --web.listen-address=":9115"
