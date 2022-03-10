#!/bin/bash
set -e

echo "starting zyte headless proxy..."
/usr/local/bin/crawlera-headless-proxy -d -c /etc/zhp/config.toml -a "$ZYTE_SPM_API_KEY"

# wait for the pid of this file to end
wait $!