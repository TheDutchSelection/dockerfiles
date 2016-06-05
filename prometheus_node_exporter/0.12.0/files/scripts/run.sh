#!/bin/bash
set -e

echo "starting prometheus node exporter..."
exec /usr/local/bin/node_exporter
