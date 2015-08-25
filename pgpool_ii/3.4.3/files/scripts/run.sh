#!/bin/bash
set -e

trap "echo \"Sending SIGTERM to processes\"; /usr/local/bin/pgpool -f /etc/pgpool/pgpool.conf -F /etc/pgpool/pcp.conf -m s stop" SIGTERM
trap "echo \"Sending SIGKILL to processes\"; /usr/local/bin/pgpool -f /etc/pgpool/pgpool.conf -F /etc/pgpool/pcp.conf -m f stop" SIGKILL

read -r -d '' pgpool_backend_base << EOM || true
backend_hostname##number## = '##host_ip##'
backend_port##number## = ##host_port##
backend_weight##number## = ##host_weight##
backend_data_directory##number## = '##host_data_directory##'
backend_flag##number## = '##host_flag##'
EOM

read -r -d '' pgpool_heartbeat_destination_base << EOM || true
heartbeat_destination##number## = '##host_ip##'
heartbeat_destination_port##number## = ##host_port##
heartbeat_device##number## = ''
EOM

read -r -d '' pgpool_other_pgpool_setting_base << EOM || true
other_pgpool_hostname##number## = '##host_ip##'
other_pgpool_port##number## = 9999
other_wd_port##number## = 9000
EOM

# $1: string
escape_string () {
  set -e
  local string_to_escape="$1"

  partially_escaped_string=$(sed 's/\//\\\//g' <<< "$string_to_escape")
  partially_escaped_string=$(sed ':a;N;$!ba;s/\n/\\n/g' <<< "$partially_escaped_string")
  escaped_string=$(sed 's/\$/\\$/g' <<< "$partially_escaped_string")

  echo "$escaped_string"
}

create_pcp_username_password () {
  set -e

  if [[ -z "$PCP_USERNAME" || -z "$PCP_USERNAME" ]]; then
    local username_password=""
  else
    local pcp_password_md5=$(/usr/local/bin/pg_md5 "$PCP_PASSWORD")
    local username_password="$PCP_USERNAME"":""$pcp_password_md5"
  fi

  echo "$username_password"
}

create_backend_settings () {
  set -e
  local envs=$(env)
  local envs=$(echo "$envs" | sort)

  local backends=""
  local counter=0
  while read -r env; do
    local host=""
    local port=""
    local weight=""
    local data_directory=""
    local flag=""
    local backend="$pgpool_backend_base"
    # we want the POSTGRESQL_[TYPE]_[APP_ID]_HOST_PRIVATE_IP=10.0.4.1 ones
    if [[ "$env" == *"_HOST_PRIVATE_IP="* && "$env" == "POSTGRESQL_"* ]]; then
      local host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host=$(echo "$env" | awk -F'=' '{print $2}')
      local port_var=${host_var/_PRIVATE_IP/_PORT}
      eval port=\$$port_var
    # we want the POSTGRESQL_[TYPE]_[APP_ID]_HOST_PUBLIC_IP=10.0.4.1 ones
    elif [[ "$env" == *"_HOST_PUBLIC_IP="* && "$env" == "POSTGRESQL_"* ]]; then
      # check if we have a private ip available, then we don't want the public one
      local temp_host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host_private_ip_var=${temp_host_var/_PUBLIC_IP/_PRIVATE_IP}
      eval host_private_ip=\$$host_private_ip_var
      if [[ -z "$host_private_ip" ]]; then
        # we want all PUBLIC_IPS for the specified availability zones
        local host_var=$(echo "$env" | awk -F'=' '{print $1}')
        local host=$(echo "$env" | awk -F'=' '{print $2}')
        local port_var=${host_var/_PUBLIC_IP/_PORT}
        eval port=\$$port_var
      fi
    fi

    if [[ ! -z "$host" && ! -z "$port" ]]; then
      # remove last 4 parts for APP, ie. NGINX_PRICE_COMPARATOR_1_HOST_PRIVATE_IP
      local app_upper=$(echo "$host_var" | awk -F'_' '{for(i = 1; i <= NF - 4; i++) printf "%s%s", $i, i == NF -4 ? "" : "_" }')
      local app=$(echo "$app_upper" | awk '{print tolower($0)}')
      # print only the 4th part from behind for id
      local app_id=$(echo "$host_var" | awk -F'_' '{print $(NF - 3) }')
      local app_id=$(echo "$app_id" | awk '{print tolower($0)}')
      # other variables
      local weight_var=${port_var/_PORT/_WEIGHT}
      local flag_var=${port_var/_PORT/_FLAG}
      eval weight=\$$weight_var
      eval flag=\$$flag_var

      local data_directory="$DATA_DIRECTORY""$app""/""$app_id"

      if [[ ! -z "$host" && ! -z "$port" && ! -z "$weight" && ! -z "$data_directory" && ! -z "$flag" ]]; then
        # put backend together
        local backend=${backend//\#\#number\#\#/"$counter"}
        local backend=${backend//\#\#host_ip\#\#/"$host"}
        local backend=${backend//\#\#host_port\#\#/"$port"}
        local backend=${backend//\#\#host_weight\#\#/"$weight"}
        local backend=${backend//\#\#host_data_directory\#\#/"$data_directory"}
        local backend=${backend//\#\#host_flag\#\#/"$flag"}

        local backends="$backends"$'\n'"$backend"$'\n'
        local counter=$((counter + 1))
      fi
    fi
  done <<< "$envs"

  echo "$backends"
}

create_heartbeat_destination_settings () {
  set -e
  local envs=$(env)
  local envs=$(echo "$envs" | sort)

  local heartbeat_destinations=""
  local counter=0
  while read -r env; do
    local host=""
    local port=""
    local heartbeat_destination="$pgpool_heartbeat_destination_base"
    # we want the PGPOOL_[TYPE]_[APP_ID]_HOST_PRIVATE_IP=10.0.4.1 ones
    if [[ "$env" == *"_HOST_PRIVATE_IP="* && "$env" == "PGPOOL_"* ]]; then
      local host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host=$(echo "$env" | awk -F'=' '{print $2}')
      local port_var=${host_var/_PRIVATE_IP/_PORT_PEER}
      eval port=\$$port_var
    # we want the PGPOOL_[TYPE]_[APP_ID]_HOST_PUBLIC_IP=10.0.4.1 ones
    elif [[ "$env" == *"_HOST_PUBLIC_IP="* && "$env" == "PGPOOL_"* ]]; then
      # check if we have a private ip available, then we don't want the public one
      local temp_host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host_private_ip_var=${temp_host_var/_PUBLIC_IP/_PRIVATE_IP}
      eval host_private_ip=\$$host_private_ip_var
      if [[ -z "$host_private_ip" ]]; then
        # we want all PUBLIC_IPS for the specified availability zones
        local host_var=$(echo "$env" | awk -F'=' '{print $1}')
        local host=$(echo "$env" | awk -F'=' '{print $2}')
        local port_var=${host_var/_PUBLIC_IP/_PORT_PEER}
        eval port=\$$port_var
      fi
    fi

    if [[ ! -z "$host" && ! -z "$port" ]]; then
      # put heartbeat_destination together
      local heartbeat_destination=${heartbeat_destination//\#\#number\#\#/"$counter"}
      local heartbeat_destination=${heartbeat_destination//\#\#host_ip\#\#/"$host"}
      local heartbeat_destination=${heartbeat_destination//\#\#host_port\#\#/"$port"}

      local heartbeat_destinations="$heartbeat_destinations"$'\n'"$heartbeat_destination"$'\n'
      local counter=$((counter + 1))
    fi
  done <<< "$envs"

  echo "$heartbeat_destinations"
}

create_other_pgpool_settings () {
  set -e
  local envs=$(env)
  local envs=$(echo "$envs" | sort)

  local other_pgpool_settings=""
  local counter=0
  while read -r env; do
    local host=""
    local other_pgpool_setting="$pgpool_other_pgpool_setting_base"
    # we want the PGPOOL_[TYPE]_[APP_ID]_HOST_PRIVATE_IP=10.0.4.1 ones
    if [[ "$env" == *"_HOST_PRIVATE_IP="* && "$env" == "PGPOOL_"* ]]; then
      local host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host=$(echo "$env" | awk -F'=' '{print $2}')
    # we want the PGPOOL_[TYPE]_[APP_ID]_HOST_PUBLIC_IP=10.0.4.1 ones
    elif [[ "$env" == *"_HOST_PUBLIC_IP="* && "$env" == "PGPOOL_"* ]]; then
      # check if we have a private ip available, then we don't want the public one
      local temp_host_var=$(echo "$env" | awk -F'=' '{print $1}')
      local host_private_ip_var=${temp_host_var/_PUBLIC_IP/_PRIVATE_IP}
      eval host_private_ip=\$$host_private_ip_var
      if [[ -z "$host_private_ip" ]]; then
        # we want all PUBLIC_IPS for the specified availability zones
        local host_var=$(echo "$env" | awk -F'=' '{print $1}')
        local host=$(echo "$env" | awk -F'=' '{print $2}')
      fi
    fi

    if [[ ! -z "$host" ]]; then
      # put other_pgpool_setting together
      local other_pgpool_setting=${other_pgpool_setting//\#\#number\#\#/"$counter"}
      local other_pgpool_setting=${other_pgpool_setting//\#\#host_ip\#\#/"$host"}

      local other_pgpool_settings="$other_pgpool_settings"$'\n'"$other_pgpool_setting"$'\n'
      local counter=$((counter + 1))
    fi
  done <<< "$envs"

  echo "$other_pgpool_settings"
}

create_log_directory () {
  local log_directory="$DATA_DIRECTORY""log"

  mkdir -p "$log_directory"

  echo "$log_directory"
}

create_pool_passwd_file () {
  set -e
  local envs=$(env)
  local envs=$(echo "$envs" | sort)

  local pool_passwd_directory="/tmp/password"
  local pool_passwd_file="$pool_passwd_directory""/pool_passwd"

  mkdir -p "$pool_passwd_directory"

  while read -r env; do
    local user=""
    local password=""
    # we want the POSTGRESQL_USER_[ID]=aap ones
    if [[ "$env" == "POSTGRESQL_USER_"* ]]; then
      local user_var=$(echo "$env" | awk -F'=' '{print $1}')
      local user=$(echo "$env" | awk -F'=' '{print $2}')
      local password_var=${user_var/_USER_/_PASSWORD_}
      eval password=\$$password_var
    fi

    if [[ ! -z "$user" && ! -z "$password" ]]; then
      # create user - password line
      /usr/local/bin/pg_md5 -m -u "$user" -f /etc/pgpool/pgpool.conf "$password"
    fi
  done <<< "$envs"

  echo "$pool_passwd_file"
}

echo "copy pcp.conf and pgpool.conf files..."
cp -p /etc/pgpool/pcp_template.conf /etc/pgpool/pcp.conf
cp -p /etc/pgpool/pgpool_template.conf /etc/pgpool/pgpool.conf

pcp_username_password=$(create_pcp_username_password)
backend_settings=$(create_backend_settings)
escaped_backend_settings=$(escape_string "$backend_settings")
heartbeat_destination_settings=$(create_heartbeat_destination_settings)
escaped_heartbeat_destination_settings=$(escape_string "$heartbeat_destination_settings")
other_pgpool_settings=$(create_other_pgpool_settings)
escaped_other_pgpool_settings=$(escape_string "$other_pgpool_settings")
log_directory=$(create_log_directory)
escaped_log_directory=$(escape_string "$log_directory")
pool_passwd_file=$(create_pool_passwd_file)
escaped_pool_passwd_file=$(escape_string "$pool_passwd_file")

echo "set values to pcp.conf file..."
sed -i "s/##pcp_username_password##/$pcp_username_password/g" /etc/pgpool/pcp.conf

echo "set values to pgpool.conf file..."
sed -i "s/##health_check_user##/$HEALTH_CHECK_USER/g" /etc/pgpool/pgpool.conf
sed -i "s/##health_check_user_password##/$HEALTH_CHECK_USER_PASSWORD/g" /etc/pgpool/pgpool.conf
sed -i "s/##recovery_user##/$RECOVERY_USER/g" /etc/pgpool/pgpool.conf
sed -i "s/##recovery_user_password##/$RECOVERY_USER_PASSWORD/g" /etc/pgpool/pgpool.conf
sed -i "s/##watchdog_trusted_servers##/$WATCHDOG_TRUSTED_SERVERS/g" /etc/pgpool/pgpool.conf
sed -i "s/##watchdog_hostname##/$HOST_IP/g" /etc/pgpool/pgpool.conf
sed -i "s/##watchdog_authkey##/$WATCHDOG_AUTHKEY/g" /etc/pgpool/pgpool.conf
sed -i "s/##watchdog_switch_method##/$WATCHDOG_SWITCH_METHOD/g" /etc/pgpool/pgpool.conf
sed -i "s/##log_directory##/$escaped_log_directory/g" /etc/pgpool/pgpool.conf
sed -i "s/##pool_passwd_file##/$escaped_pool_passwd_file/g" /etc/pgpool/pgpool.conf
perl -i -pe 's/##backend_settings##/'"${escaped_backend_settings}"'/g' /etc/pgpool/pgpool.conf
perl -i -pe 's/##heartbeat_destination_settings##/'"${escaped_heartbeat_destination_settings}"'/g' /etc/pgpool/pgpool.conf
perl -i -pe 's/##other_pgpool_settings##/'"${escaped_other_pgpool_settings}"'/g' /etc/pgpool/pgpool.conf

echo "starting pgpool..."
/usr/local/bin/pgpool -f /etc/pgpool/pgpool.conf -F /etc/pgpool/pcp.conf -n &

# wait for the pid of this file to end
wait $!