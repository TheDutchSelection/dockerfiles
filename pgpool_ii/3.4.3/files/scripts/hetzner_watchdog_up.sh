#!/bin/bash
set -e

switch_ip () {
  result=$(curl -u \'"$HETZNER_WEBSERVICE_USERNAME"\':\'"$HETZNER_WEBSERVICE_PASSWORD"\' https://robot-ws.your-server.de/failover/"$SWITCHABLE_IP" -d active_server_ip="$HOST_IP")

  echo "$result"
}

echo "switching ip $SWITCHABLE_IP to server $HOST_IP ..."

counter=0
while [[ "$counter" < 10 ]]; do
  switch_result=$(switch_ip)
  echo "$switch_result"
  if [[ "$switch_result" == *"error"* ]]; then
    sleep 5
  else
    exit 0
  fi

  counter=$((counter + 1))
done
