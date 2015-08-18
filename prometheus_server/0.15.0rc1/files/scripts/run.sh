#!/bin/bash
set -e

trap "echo \"Sending SIGTERM to processes\"; killall -s SIGTERM -w prometheus" SIGTERM

read -r -d '' prometheus_base << EOM || true
global:
  scrape_interval: "15s"
  scrape_timeout: "10s"
  evaluation_interval: "15s"

rule_files:
- "/etc/prometheus/prometheus.rules"

scrape_configs:
EOM

read -r -d '' prometheus_hosts_job << EOM || true
- job_name: "hosts"
  scheme: "http"
  metrics_path: "/metrics"
  target_groups:
EOM

read -r -d '' prometheus_containers_job << EOM || true
- job_name: "containers"
  scheme: "http"
  metrics_path: "/metrics"
  target_groups:
EOM

hosts_job () {
  set -e

  local envs=$(env)
  local targets=""

  while read -r env; do
    # we want the only the [HOST]_PUBLIC_IP=188.90.45.31 ones
    local number_of_dashes=$(grep -o "_" <<< "$env" | wc -l)
    if [[ "$env" == *"_PUBLIC_IP="* && "$number_of_dashes" == "2" ]]; then
      local host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host=$(echo "$env" | awk -F'=' '{print $2}')
      local host_name=${host_var%%_*}
      local host_name=$(echo "$host_name" | awk '{print tolower($0)}')

      local target="    - ""$host"":9100"
      local labels="    labels:"$'\n'"      node: ""$host_name"
      local target_groups="$target_groups"$'\n'"  - targets:"$'\n'"$target"$'\n'"$labels"
    fi
  done <<< "$envs"

  echo "$target_groups"
}

containers_job () {
  set -e
  echo ""
}

create_jobs () {
  set -e

  local hosts_job=$(hosts_job)
  local containers_job=$(containers_job)
  # local jobs="$prometheus_hosts_job""$hosts_job"$'\n'$'\n'"$prometheus_containers_job""$containers_job"
  local jobs="$prometheus_hosts_job""$hosts_job"

  echo "$jobs"
}

# $1: prometheus base
# $2: prometheus config file
create_config_file () {
  set -e
  local prometheus_base="$1"
  local prometheus_conf_file="$2"

  cat /dev/null > "$prometheus_conf_file"

  local jobs=$(create_jobs)

  echo "$prometheus_base"$'\n' >> "$prometheus_conf_file"
  echo "$jobs" >> "$prometheus_conf_file"
}

prometheus_conf_file="/etc/prometheus/prometheus.yml"

echo "creating data directory..."
mkdir -p "$DATA_DIRECTORY"

echo "creating $prometheus_conf_file..."
create_config_file "$prometheus_base" "$prometheus_conf_file"

if [[ -z "$ALERTMANAGER_HOST" || -z "$ALERTMANAGER_PORT" ]]; then
  echo "starting prometheus without alertmanager..."
  exec /usr/local/bin/prometheus \
    -config.file=/etc/prometheus/prometheus.yml \
    -storage.local.path="$DATA_DIRECTORY" \
    -storage.local.memory-chunks="$MEMORY_CHUNCKS"
else
  echo "starting prometheus with alert manager at ""$ALERTMANAGER_HOST"":""$ALERTMANAGER_PORT""..."
  exec /usr/local/bin/prometheus \
    -config.file=/etc/prometheus/prometheus.yml \
    -storage.local.path="$DATA_DIRECTORY" \
    -storage.local.memory-chunks="$MEMORY_CHUNCKS" \
    -alertmanager.url=http://"$ALERTMANAGER_HOST":"$ALERTMANAGER_PORT"
fi
