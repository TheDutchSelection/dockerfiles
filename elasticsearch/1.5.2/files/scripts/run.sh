#!/bin/bash
set -e

create_unicast_hosts () {
  local envs=$(env)
  local envs=$(echo "$envs" | sort)

  local unicast_hosts="["
  while read -r env; do
    local host=""
    local port=""
    if [[ "$env" == "ELASTICSEARCH_MASTER_"* && "$env" == *"_HOST_PRIVATE_IP="* ]]; then
      local host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host=$(echo "$env" | awk -F'=' '{print $2}')
      local port_var=${host_var/_PRIVATE_IP/_PORT_PEER}
      eval port=\$$port_var
    elif [[ "$env" == "ELASTICSEARCH_MASTER_"* && "$env" == *"_HOST_PUBLIC_IP"* ]]; then
      # check if we have a private ip available, then we don't want the public one
      local temp_host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host_private_ip_var=${temp_host_var/_PUBLIC_IP/_PRIVATE_IP}
      eval host_private_ip=\$$host_private_ip_var
      if [[ -z "$host_private_ip" ]]; then
        local host_var=$(echo "$env" | awk -F'=' '{print $1}')
        local host=$(echo "$env" | awk -F'=' '{print $2}')
        local port_var=${host_var/_PUBLIC_IP/_PORT_PEER}
        eval port=\$$port_var
      fi
    fi

    if [[ ! -z "$host" && ! -z "$port" ]]; then
      local unicast_host="$host:$port"

      if [[ "$unicast_hosts" == "[" ]]; then
        local unicast_hosts="$unicast_hosts\"$unicast_host\""
      else
        local unicast_hosts="$unicast_hosts, \"$unicast_host\""
      fi
    fi

  done <<< "$envs"

  echo "$unicast_hosts""]"
}

# $1: elasticsearch config file
create_config_file () {
  set -e
  local elasticsearch_config_file="$1"

  local unicast_hosts=$(create_unicast_hosts)

  sed -i "s/##unicast_hosts##/$unicast_hosts/g" "$elasticsearch_config_file"
}

elasticsearch_config_file="/usr/local/bin/elasticsearch/config/elasticsearch.yml"

echo "creating persistant directories..."
mkdir -p "$PATH_DATA"
mkdir -p "$PATH_WORK"
mkdir -p "$PATH_LOGS"

echo "creating $elasticsearch_config_file..."
create_config_file "$elasticsearch_config_file"

echo "starting elasticsearch..."
exec /usr/local/bin/elasticsearch/bin/elasticsearch