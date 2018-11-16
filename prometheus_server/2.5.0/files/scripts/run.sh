#!/bin/bash
set -e

trap "echo \"Sending SIGTERM to processes\"; killall -s SIGTERM -w prometheus" SIGTERM

read -r -d '' prometheus_base << EOM || true
global:
  scrape_interval: "15s"
  scrape_timeout: "10s"
  evaluation_interval: "15s"

rule_files:
- "/etc/prometheus/prometheus.rules.yml"

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      - ##alertmanager_host##:##alertmanager_port##

scrape_configs:
EOM

read -r -d '' prometheus_hosts_job << EOM || true
- job_name: "hosts"
  scheme: "http"
  metrics_path: "/metrics"
  static_configs:
EOM

read -r -d '' prometheus_blackbox_job_base << EOM || true
- job_name: "blackbox_##job_name##"
  scheme: "http"
  metrics_path: "/probe"
  params:
    target: ["##target_param##"]
    module: ["##module_param##"]
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
      local host_name=${host_var:5:15} # string manipulation starting at 5, 15 chars
      local host_name=${host_name:0:5}"."${host_name:5:3}"."${host_name:8:4}"."${host_name:12:3}
      local host_name=$(echo "$host_name" | awk '{print tolower($0)}')

      local target="    - ""$host"":9100"
      local labels="    labels:"$'\n'"      node: ""$host_name"
      local target_groups="$target_groups"$'\n'"  - targets:"$'\n'"$target"$'\n'"$labels"
    fi
  done <<< "$envs"

  echo "$target_groups"
}

blackbox_jobs () {
  set -e

  local envs=$(env)
  local targets=""

  while read -r env; do
    # we want only the BLACKBOX_PROBE_URL_[TARGET_NAME]=localhost:9115/probe?target%3Dgoogle.com&module%3Dhttp_2xx ones
    if [[ "$env" == "BLACKBOX_PROBE_URL"* ]]; then
      local url_var=$(echo "$env" | awk -F'=' '{print $1}')
      local url=$(echo "$env" | awk -F'=' '{print $2}')
      local host_plus_port=${url%%/*}
      local job_name=${url_var:19} # string manipulation starting at 19
      local job_name=$(echo "$job_name" | awk '{print tolower($0)}')
      local target_name=${job_name//_/ }
      local metrics_path=${url#*/}
      local target_param=$(echo "$metrics_path" | sed 's/.*target%3D//' | sed 's/\&.*//')
      local target_param=${target_param//%3D/=}
      local module_param=$(echo "$metrics_path" | sed 's/.*module%3D//' | sed 's/\&.*//')

      local job="$prometheus_blackbox_job_base"
      local job=${job/\#\#job_name\#\#/"$job_name"}
      local job=${job/\#\#target_param\#\#/"$target_param"}
      local job=${job/\#\#module_param\#\#/"$module_param"}

      local target="    - ""$host_plus_port"
      local labels="    labels:"$'\n'"      target_name: \"""$target_name""\""
      local job="$job"$'\n'"  - targets:"$'\n'"$target"$'\n'"$labels"
      local jobs="$jobs"$'\n'"$job"
    fi
  done <<< "$envs"

  echo "$jobs"
}

create_jobs () {
  set -e

  local hosts_job=$(hosts_job)
  local blackbox_jobs=$(blackbox_jobs)
  local jobs=""
  if [[ ! -z "$hosts_job" ]]; then
    local jobs="$jobs""$prometheus_hosts_job""$hosts_job"$'\n'$'\n'
  fi

  if [[ ! -z "$blackbox_jobs" ]]; then
    local jobs="$jobs""$blackbox_jobs"
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

  local prometheus_base=${prometheus_base//\#\#alertmanager_host\#\#/"$ALERTMANAGER_HOST"}
  local prometheus_base=${prometheus_base//\#\#alertmanager_port\#\#/"$ALERTMANAGER_PORT"}

  local jobs=$(create_jobs)

  echo "$prometheus_base"$'\n' >> "$prometheus_conf_file"
  echo "$jobs" >> "$prometheus_conf_file"
}

echo "creating data directory..."
mkdir -p "$DATA_DIRECTORY"

echo "copy conf file.."
cp -p /etc/prometheus/prometheus_template.rules.yml /etc/prometheus/prometheus.rules.yml

echo "creating $prometheus_conf_file..."
prometheus_conf_file="/etc/prometheus/prometheus.yml"
create_config_file "$prometheus_base" "$prometheus_conf_file"

echo "starting prometheus with alert manager at ""$ALERTMANAGER_HOST"":""$ALERTMANAGER_PORT""..."
exec /usr/local/bin/prometheus \
  --config.file="$prometheus_conf_file" \
  --storage.tsdb.path="$DATA_DIRECTORY" \
  --log.level="debug"
