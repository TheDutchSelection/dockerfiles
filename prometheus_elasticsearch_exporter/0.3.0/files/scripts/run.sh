#!/bin/bash
set -e

echo "starting prometheus node exporter..."
exec /usr/local/bin/elasticsearch_exporter -es.all=false -es.uri="$ELASTICSEARCH_URI" -web.listen-address=9108
