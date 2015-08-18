#!/bin/bash
#
# REQUIRED ENVS:
# REDIS_APP (ie. "price_comparator_nl_telecom")
# REDIS_APP_ENV (ie. "wrkprd", "wrkstg", "local")

set -e

# include dependencies
curl -L -o /usr/local/bin/redis_helper https://raw.githubusercontent.com/TheDutchSelection/captain/master/docker/captain_services_base/latest/files/scripts/redis_helper
chmod +x /usr/local/bin/redis_helper
dir="${BASH_SOURCE%/*}"
if [[ ! -d "$dir" ]]; then dir="$PWD"; fi
. "$dir/redis_helper"

# $1: redis app
# $2: redis app env
get_app_env_keys () {
  set -e
  local redis_app="$1"
  local redis_app_env="$2"
  local keys=""

  local redis_keys=$(get_redis_keys "$redis_namespace""*:""$redis_app""*")

  for redis_key in $redis_keys
  do
    if [[ "$redis_key" == *"$redis_app_env"* ]]; then
      if [[ -z "$keys" ]]; then
        local keys="$redis_key"
      else
        local keys="$keys"$'\n'"$redis_key"
      fi
    fi
  done

  echo "$keys"
}

if [[ -z "$REDIS_APP" || -z "$REDIS_APP_ENV" ]]; then
  echo "REDIS_APP or REDIS_APP_ENV variables not set..."
  exit 1
fi

# get all keys with REDIS_APP and REDIS_APP_ENV
app_env_keys=$(get_app_env_keys "$REDIS_APP" "$REDIS_APP_ENV")

# set update and need_restart fields for app_env_keys to true
echo -e $(set_redis_hash_field_from_keys "$app_env_keys" "$redis_update_field" "$redis_true_value")
echo -e $(set_redis_hash_field_from_keys "$app_env_keys" "$redis_need_restart_field" "$redis_true_value")

# check update, need_restart and restart fields for false for app_env_keys
end_loop="false"
while [[ ! "$end_loop" == "true" ]]; do
  result=$(check_all_redis_hash_fields_from_keys "$app_env_keys" "$redis_true_value")
  if [[ "$result" == "false" ]]; then
    end_loop="true"
    echo "$REDIS_APP deployed in $REDIS_APP_ENV"
  else
    echo -e "$result"
  fi

  sleep 5
done
