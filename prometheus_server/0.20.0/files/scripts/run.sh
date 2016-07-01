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
  static_configs:
EOM

read -r -d '' prometheus_elasticsearch_job << EOM || true
- job_name: "elasticsearch"
  scheme: "http"
  metrics_path: "/metrics"
  static_configs:
EOM

read -r -d '' prometheus_blackbox_job << EOM || true
- job_name: "blackbox"
  scheme: "http"
  metrics_path: ""
  static_configs:
EOM

hosts_job () {
  set -e

  local envs=$(env)
  local targets=""

  while read -r env; do
    # we want the only the HOST_[HOST]_PUBLIC_IP=188.90.45.31 ones
    local number_of_dashes=$(grep -o "_" <<< "$env" | wc -l)
    if [[ "$env" == "HOST_"*"_PUBLIC_IP="* && "$number_of_dashes" == "3" ]]; then
      local host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host=$(echo "$env" | awk -F'=' '{print $2}')
      local name=${host_var:5:13} # string manipulation starting at 5, 13 chars
      local name=$(echo "$name" | awk '{print tolower($0)}')

      local target="    - ""$host"":9100"
      local labels="    labels:"$'\n'"      node: ""$name"
      local target_groups="$target_groups"$'\n'"  - targets:"$'\n'"$target"$'\n'"$labels"
    fi
  done <<< "$envs"

  echo "$target_groups"
}

elasticsearch_job () {
  set -e

  local envs=$(env)
  local targets=""

  while read -r env; do
    # we want the only the ELASTICSEARCH_[HOST]_PUBLIC_IP=188.90.45.31 ones
    local number_of_dashes=$(grep -o "_" <<< "$env" | wc -l)
    if [[ "$env" == "ELASTICSEARCH_"*"_PUBLIC_IP="* && "$number_of_dashes" == "3" ]]; then
      local host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host=$(echo "$env" | awk -F'=' '{print $2}')
      local host_name=${host_var:14:13} # string manipulation starting at 14, 13 chars
      local host_name=$(echo "$host_name" | awk '{print tolower($0)}')

      local target="    - ""$host"":9108"
      local labels="    labels:"$'\n'"      elasticsearch_node: ""$host_name"
      local target_groups="$target_groups"$'\n'"  - targets:"$'\n'"$target"$'\n'"$labels"
    fi
  done <<< "$envs"

  echo "$target_groups"
}

blackbox_job () {
  set -e

  local envs=$(env)
  local targets=""

  while read -r env; do
    # we want only the BLACKBOX_PROBE_URL_[TARGET_NAME]=http://localhost:9115/probe?target=google.com&module=http_2xx ones
    if [[ "$env" == "BLACKBOX_PROBE_URL"* ]]; then
      local url_var=$(echo "$env" | awk -F'=' '{print $1}')
      local url=$(echo "$env" | awk -F'=' '{print $2}')
      local target_name=${url_var##*_}
      local target_name=$(echo "$target_name" | awk '{print tolower($0)}')
      local target_name=${target_name//-/ }

      local target="    - ""$url"
      local labels="    labels:"$'\n'"      target_name: ""$target_name"
      local target_groups="$target_groups"$'\n'"  - targets:"$'\n'"$target"$'\n'"$labels"
    fi
  done <<< "$envs"

  echo "$target_groups"
}

create_jobs () {
  set -e

  local hosts_job=$(hosts_job)
  local elasticsearch_job=$(elasticsearch_job)
  local blackbox_job=$(blackbox_job)
  local jobs=""
  if [[ ! -z "$hosts_job" ]]; then
    local jobs="$jobs""$prometheus_hosts_job""$hosts_job"$'\n'$'\n'
  fi
  if [[ ! -z "$elasticsearch_job" ]]; then
    local jobs="$jobs""$prometheus_elasticsearch_job""$elasticsearch_job"$'\n'$'\n'
  fi

  if [[ ! -z "$blackbox_job" ]]; then
    local jobs="$jobs""$prometheus_blackbox_job""$blackbox_job"
  fi

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
