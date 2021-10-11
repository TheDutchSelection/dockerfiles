#!/bin/bash
set -e

create_initial_master_nodes () {
  local envs=$(env)
  local envs=$(echo "$envs" | sort)

  local initial_master_nodes="["
  while read -r env; do
    local node_name=""
    if [[ "$env" == "ELASTICSEARCH_MASTER_"* && "$env" == *"_NODE_NAME="* ]]; then
      local node_name=$(echo "$env" | awk -F'=' '{print $2}')
    fi

    if [[ ! -z "$node_name" ]]; then
      if [[ "$initial_master_nodes" == "[" ]]; then
        local initial_master_nodes="$initial_master_nodes\"$node_name\""
      else
        local initial_master_nodes="$initial_master_nodes, \"$node_name\""
      fi
    fi

  done <<< "$envs"

  echo "$initial_master_nodes""]"
}

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
  local initial_master_nodes=$(create_initial_master_nodes)

  sed -i "s/##unicast_hosts##/$unicast_hosts/g" "$elasticsearch_config_file"
  sed -i "s/##initial_master_nodes##/$initial_master_nodes/g" "$elasticsearch_config_file"
}

elasticsearch_config_file="/etc/elasticsearch/elasticsearch.yml"

echo "creating persistant directories..."
mkdir -p "$PATH_DATA"
mkdir -p "$PATH_LOGS"

echo "creating $elasticsearch_config_file..."
create_config_file "$elasticsearch_config_file"

echo "starting elasticsearch..."
exec /usr/share/elasticsearch/bin/elasticsearch
