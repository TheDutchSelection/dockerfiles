#!/bin/bash
set -e

trap "echo \"Sending SIGTERM to processes\"; killall -s SIGTERM -w postgres;" SIGTERM

read -r -d '' recovery_conf_base << EOM || true
primary_conninfo = 'host=##master_host_ip## port=##master_host_port## user=##replicator_user## password=##replicator_password##'
trigger_file = '##data_directory##/failover'
standby_mode = 'on'
EOM

read -r -d '' authentication_setting_base << EOM || true
##type##  ##database##  ##user##  ##address## ##auth_method##
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

create_authentication_settings () {
  set -e

  local authentication_setting="$authentication_setting_base"

  local authentication_setting_1=${authentication_setting//\#\#type\#\#/"host"}
  local authentication_setting_1=${authentication_setting_1//\#\#database\#\#/"all"}
  local authentication_setting_1=${authentication_setting_1//\#\#user\#\#/"all"}
  local authentication_setting_1=${authentication_setting_1//\#\#address\#\#/"0.0.0.0/0"}
  if [[ "$RUN_AS_DEVELOPMENT" == "1" ]]; then
    local authentication_setting_1=${authentication_setting_1//\#\#auth_method\#\#/"trust"}
  else
    local authentication_setting_1=${authentication_setting_1//\#\#auth_method\#\#/"md5"}
  fi

  local authentication_setting_2=${authentication_setting_1//0\.0\.0\.0\/0/"::1/128"}

  local authentication_setting_3=${authentication_setting//\#\#type\#\#/"host"}
  local authentication_setting_3=${authentication_setting_3//\#\#database\#\#/"replication"}
  local authentication_setting_3=${authentication_setting_3//\#\#user\#\#/"all"}
  local authentication_setting_3=${authentication_setting_3//\#\#address\#\#/"0.0.0.0/0"}
  local authentication_setting_3=${authentication_setting_3//\#\#auth_method\#\#/"md5"}

  local authentication_settings="$authentication_setting_1"$'\n'"$authentication_setting_2"$'\n'"$authentication_setting_3"$'\n'

  echo "$authentication_settings"
}

create_wale_prefix () {
  set -e

  if [[ -z "$AWS_S3_WALE_BUCKET_BASE_PATH" || "$AWS_S3_WALE_BUCKET_BASE_PATH" == "/" ]]; then
    local wale_s3_prefix="s3://""$AWS_S3_WALE_BUCKET_NAME""/""$HOST_IP"
  else
    local wale_s3_prefix"s3://""$AWS_S3_WALE_BUCKET_NAME""/""$AWS_S3_WALE_BUCKET_BASE_PATH""$HOST_IP"
  fi

  echo "$wale_s3_prefix"
}

create_postgresql_conf () {
  set -e

  local escaped_data_directory=$(escape_string "$DATA_DIRECTORY")
  local archive_dummy_directory="$DATA_DIRECTORY""pg_xlog/dummy_archive/"

  if [[ -z "$MAX_CONNECTIONS" ]]; then
    local calculated_max_connections="500"
  else
    local calculated_max_connections="$MAX_CONNECTIONS"
  fi

  if [[ -z "$MAX_REPLICATION_SLOTS" ]]; then
    local calculated_max_replication_slots="0"
  else
    local calculated_max_replication_slots="$MAX_REPLICATION_SLOTS"
  fi

  if [[ -z "$MAX_WAL_SENDERS" ]]; then
    local calculated_max_wal_senders="0"
  else
    local calculated_max_wal_senders="$MAX_WAL_SENDERS"
  fi

  if [[ -z "$SHARED_BUFFERS" ]]; then
    local calculated_shared_buffers="1"
  else
    local calculated_shared_buffers="$SHARED_BUFFERS"
  fi

  sed -i "s/##data_directory##/$escaped_data_directory/g" /etc/postgresql/postgresql.conf
  sed -i "s/##max_connections##/$calculated_max_connections/g" /etc/postgresql/postgresql.conf
  sed -i "s/##max_replication_slots##/$calculated_max_replication_slots/g" /etc/postgresql/postgresql.conf
  sed -i "s/##max_wal_senders##/$calculated_max_wal_senders/g" /etc/postgresql/postgresql.conf
  sed -i "s/##shared_buffers##/$calculated_shared_buffers/g" /etc/postgresql/postgresql.conf

  if [[ ! -z "$AWS_ACCESS_KEY_ID" && ! -z "$AWS_S3_WALE_BUCKET_NAME" && ! -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    local wale_s3_prefix=$(create_wale_prefix)

    local archive_mode="on"
    local archive_command="wal-e --s3-prefix=""$wale_s3_prefix"" wal-push %p"
  else
    local archive_mode="off"
    local archive_command=""
  fi

  escaped_archive_command=$(escape_string "$archive_command")

  sed -i "s/##archive_mode##/$archive_mode/g" /etc/postgresql/postgresql.conf
  sed -i "s/##archive_command##/$escaped_archive_command/g" /etc/postgresql/postgresql.conf
}

# $1: recovery_conf_base
# $2: recovery_conf file
create_recovery_conf () {
  set -e
  local recovery_conf_base="$1"
  local recovery_conf_file="$2"

  cat /dev/null > "$recovery_conf_file"

  local recovery_conf=${recovery_conf_base/\#\#master_host_ip\#\#/"$MASTER_HOST_IP"}
  local recovery_conf=${recovery_conf_base/\#\#master_host_port\#\#/"$MASTER_HOST_PORT"}
  local recovery_conf=${recovery_conf_base/\#\#replicator_user\#\#/"$REPLICATOR_USER"}
  local recovery_conf=${recovery_conf_base/\#\#replicator_password\#\#/"$REPLICATOR_PASSWORD"}
  local recovery_conf=${recovery_conf_base/\#\#data_directory\#\#/"$DATA_DIRECTORY"}

  echo "$recovery_conf" >> "$recovery_conf_file"
}

# description: init the data directory and create the superuser
init_data_directory_and_create_superuser() {
  # if data directory exist, we assume the superuser is also already created
  if [[ ! $(ls -A "$DATA_DIRECTORY") ]]; then
    echo "initializing $DATA_DIRECTORY..."
    mkdir -p "$DATA_DIRECTORY"
    cp -R /var/lib/postgresql/9.6/main/* "$DATA_DIRECTORY"

    # import base backup if this is a slave
    if [[ "$ROLE" == "slave" ]]; then
      echo "import base backup..."
      export PGPASSWORD="$SUPERUSER_PASSWORD"
      pg_basebackup -h "$MASTER_HOST_IP" -p "$MASTER_HOST_PORT" -D "$DATA_DIRECTORY" -U "$SUPERUSER_USERNAME" -v -x
      unset PGPASSWORD
    fi

    # wait for postgresql to start
    echo "waiting for postgresql to be started..."
    while [[ ! -e /run/postgresql/9.6-main.pid ]] ; do
      inotifywait -q -e create /run/postgresql/ >> /dev/null
    done

    sleep 2

    if [[ ! -z "$SUPERUSER_USERNAME" ]]; then
      echo "creating superuser $SUPERUSER_USERNAME..."
      psql -q <<-EOF
        DROP ROLE IF EXISTS $SUPERUSER_USERNAME;
        CREATE ROLE $SUPERUSER_USERNAME WITH ENCRYPTED PASSWORD '$SUPERUSER_PASSWORD';
        ALTER USER $SUPERUSER_USERNAME WITH ENCRYPTED PASSWORD '$SUPERUSER_PASSWORD';
        ALTER ROLE $SUPERUSER_USERNAME WITH SUPERUSER;
        ALTER ROLE $SUPERUSER_USERNAME WITH LOGIN;
EOF
    fi

    echo "recreating template1..."
    psql -q <<-EOF
      UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';
      DROP DATABASE template1;
      CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UNICODE';
      UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1';
EOF

    echo "vacuum freeze template1..."
    psql -q <<-EOF
      \c template1
      VACUUM FREEZE;
EOF

  fi
}

periodically_backup () {
  if [[ ! -z "$AWS_ACCESS_KEY_ID" && ! -z "$AWS_S3_WALE_BUCKET_NAME" && ! -z "$AWS_SECRET_ACCESS_KEY" && ! -z "$BACKUP_EXECUTION_TIME" ]]; then
    while true; do
      sleep 45

      local current_time=$(date +"%H:%M")
      if [[ "$current_time" == "$BACKUP_EXECUTION_TIME" ]]; then
        local wale_s3_prefix=$(create_wale_prefix)
        wal-e --s3-prefix="$wale_s3_prefix" backup-push "$DATA_DIRECTORY"
        wal-e --s3-prefix="$wale_s3_prefix" delete --confirm retain 30
      fi
    done
  fi
}

# remove any existing postgresql pid
rm -f /run/postgresql/*.pid

# create stats_temp_directory if not exists
mkdir -p /var/run/postgresql/9.6-main.pg_stat_tmp

echo "copy conf files.."
cp -p /etc/postgresql/postgresql_template.conf /etc/postgresql/postgresql.conf
cp -p /etc/postgresql/pg_hba_template.conf /etc/postgresql/pg_hba.conf

echo "set values to postgresql.conf file..."
create_postgresql_conf

echo "set values to pg_hba.conf..."
authentication_settings=$(create_authentication_settings)
escaped_authentication_settings=$(escape_string "$authentication_settings")
perl -i -pe 's/##authentication_settings##/'"${escaped_authentication_settings}"'/g' /etc/postgresql/pg_hba.conf

if [[ "$ROLE" == "slave" ]]; then
  create_recovery_conf "$recovery_conf_base" "$DATA_DIRECTORY""recovery.conf"
fi

init_data_directory_and_create_superuser &

sleep 2

if [[ ! -z "$AWS_ACCESS_KEY_ID" && ! -z "$AWS_S3_WALE_BUCKET_NAME" && ! -z "$AWS_SECRET_ACCESS_KEY" && ! -z "$BACKUP_EXECUTION_TIME" ]]; then
  echo "start periodically backup at $BACKUP_EXECUTION_TIME""h..."
  periodically_backup &
fi

echo "starting postgresql..."
/usr/lib/postgresql/9.6/bin/postgres -c config_file=/etc/postgresql/postgresql.conf &

# wait for the pid of this file to end
wait $!
