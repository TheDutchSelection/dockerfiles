#!/bin/bash
set -e

escape_string () {
  set -e
  local string_to_escape="$1"

  partially_escaped_string=$(sed 's/\//\\\//g' <<< "$string_to_escape")
  partially_escaped_string=$(sed ':a;N;$!ba;s/\n/\\n/g' <<< "$partially_escaped_string")
  escaped_string=$(sed 's/\$/\\$/g' <<< "$partially_escaped_string")

  echo "$escaped_string"
}

create_elasticsearch_hosts () {
  local envs=$(env)
  local envs=$(echo "$envs" | sort)

  local elasticsearch_hosts="["
  while read -r env; do
    local endpoint=""
    if [[ "$env" == "ELASTICSEARCH_"* && "$env" == *"_ENDPOINT="* ]]; then
      local endpoint_var=$(echo "$env" | awk -F'=' '{print $1}')
      local endpoint=$(echo "$env" | awk -F'=' '{print $2}')
    fi

    if [[ ! -z "$endpoint" ]]; then
      local escaped_endpoint=$(escape_string "$endpoint")

      if [[ "$elasticsearch_hosts" == "[" ]]; then
        local elasticsearch_hosts="$elasticsearch_hosts\"$escaped_endpoint\""
      else
        local elasticsearch_hosts="$elasticsearch_hosts, \"$escaped_endpoint\""
      fi
    fi

  done <<< "$envs"

  echo "$elasticsearch_hosts""]"
}

# $1: elasticsearch config file
create_config_file () {
  set -e
  local elasticsearch_config_file="$1"

  local elasticsearch_hosts=$(create_elasticsearch_hosts)

  sed -i "s/##elasticsearch_hosts##/$elasticsearch_hosts/g" "$elasticsearch_config_file"
}

kibana_config_file="/etc/kibana/kibana.yml"

echo "creating persistant directories..."
mkdir -p "$PATH_DATA"

echo "creating $kibana_config_file..."
create_config_file "$kibana_config_file"

#create_superuser

echo "starting kibana..."
exec /usr/share/kibana/bin/kibana
