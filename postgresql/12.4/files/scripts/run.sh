#!/bin/bash
set -e

trap "echo \"Sending SIGTERM to processes\"; killall -s SIGTERM -w postgres;" SIGTERM

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

create_postgresql_conf () {
  set -e

  local escaped_data_directory=$(escape_string "$DATA_DIRECTORY")
  local escaped_promote_trigger_file=$(escape_string "$DATA_DIRECTORY""failover.signal")

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


  if [[ ! -z "$AWS_ACCESS_KEY_ID" && ! -z "$AWS_S3_WALG_BUCKET_NAME" && ! -z "$AWS_SECRET_ACCESS_KEY" ]]; then
    local archive_mode="on"
    local archive_command="wal-g wal-push %p --pghost=/var/run/postgresql/"
    local primary_conninfo="host=""$MASTER_HOST_IP"" port=""$MASTER_HOST_PORT"" user=""$REPLICATOR_USER"" password=""$REPLICATOR_PASSWORD"
    local recovery_target_time="$RECOVERY_TARGET_TIME"
    local restore_command="wal-g wal-fetch %f %p --pghost=/var/run/postgresql/ --walg-s3-prefix s3://""$AWS_S3_WALG_BUCKET_NAME""/""$BACKUP_HOST_IP"
  else
    local archive_mode="off"
    local archive_command=""
    local primary_conninfo=""
    local recovery_target_time=""
    local restore_command=""
  fi

  escaped_archive_command=$(escape_string "$archive_command")
  escaped_primary_conninfo=$(escape_string "$primary_conninfo")
  escaped_recovery_target_time=$(escape_string "$recovery_target_time")
  escaped_restore_command=$(escape_string "$restore_command")

  sed -i "s/##archive_command##/$escaped_archive_command/g" /etc/postgresql/12/main/postgresql.conf
  sed -i "s/##archive_mode##/$archive_mode/g" /etc/postgresql/12/main/postgresql.conf
  sed -i "s/##data_directory##/$escaped_data_directory/g" /etc/postgresql/12/main/postgresql.conf
  sed -i "s/##max_connections##/$calculated_max_connections/g" /etc/postgresql/12/main/postgresql.conf
  sed -i "s/##max_replication_slots##/$calculated_max_replication_slots/g" /etc/postgresql/12/main/postgresql.conf
  sed -i "s/##max_wal_senders##/$calculated_max_wal_senders/g" /etc/postgresql/12/main/postgresql.conf
  sed -i "s/##primary_conninfo##/$escaped_primary_conninfo/g" /etc/postgresql/12/main/postgresql.conf
  sed -i "s/##promote_trigger_file##/$escaped_promote_trigger_file/g" /etc/postgresql/12/main/postgresql.conf
  sed -i "s/##recovery_target_time##/$escaped_recovery_target_time/g" /etc/postgresql/12/main/postgresql.conf
  sed -i "s/##restore_command##/$escaped_restore_command/g" /etc/postgresql/12/main/postgresql.conf
  sed -i "s/##shared_buffers##/$calculated_shared_buffers/g" /etc/postgresql/12/main/postgresql.conf
}

set_environment_variables_wal_g() {
  echo "AWS_ACCESS_KEY_ID=""$AWS_ACCESS_KEY_ID"
  echo "AWS_SECRET_ACCESS_KEY=""$AWS_SECRET_ACCESS_KEY"
  echo "AWS_REGION=""$AWS_REGION"
  export WALG_S3_PREFIX="s3://""$AWS_S3_WALG_BUCKET_NAME""/""$HOST_IP"
  echo "WALG_S3_PREFIX=""$WALG_S3_PREFIX"
}

# description: init the data directory
init_data_directory() {
  echo "initializing $DATA_DIRECTORY..."
  mkdir -p "$DATA_DIRECTORY"

  # do slave related tasks
  if [[ "$ROLE" == "slave" ]]; then
    echo "import base backup..."
    export PGPASSWORD="$SUPERUSER_PASSWORD"
    pg_basebackup -h "$MASTER_HOST_IP" -p "$MASTER_HOST_PORT" -D "$DATA_DIRECTORY" -U "$SUPERUSER_USERNAME" -v
    unset PGPASSWORD
    touch "$DATA_DIRECTORY""standby.signal"
  else
    echo "copying files into data directory..."
    cp -R /var/lib/postgresql/12/main/* "$DATA_DIRECTORY"
  fi
}

# create the superuser
create_superuser_and_template1() {
  # wait for postgresql to start
  echo "waiting for postgresql to be started..."
  while [[ ! -e /run/postgresql/12-main.pid ]] ; do
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
}

periodically_backup() {
  while true; do
    sleep 45

    local current_time=$(date +"%H:%M")
    if [[ "$current_time" == "$BACKUP_EXECUTION_TIME" ]]; then
      wal-g backup-push "$DATA_DIRECTORY" --pghost=/var/run/postgresql/
      wal-g delete retain 30 --confirm --pghost=/var/run/postgresql/
    fi
  done
}

# remove any existing postgresql pid
rm -f /var/run/postgresql/*.pid

# create stats_temp_directory if not exists
mkdir -p /var/run/postgresql/12-main.pg_stat_tmp

echo "copy conf files.."
cp -p /etc/postgresql/12/main/postgresql_template.conf /etc/postgresql/12/main/postgresql.conf
cp -p /etc/postgresql/12/main/pg_hba_template.conf /etc/postgresql/12/main/pg_hba.conf

echo "set values to postgresql.conf file..."
create_postgresql_conf

echo "set values to pg_hba.conf..."
authentication_settings=$(create_authentication_settings)
escaped_authentication_settings=$(escape_string "$authentication_settings")
perl -i -pe 's/##authentication_settings##/'"${escaped_authentication_settings}"'/g' /etc/postgresql/12/main/pg_hba.conf

echo "set environment variables for wal-g..."
set_environment_variables_wal_g

# if data directory exist, we assume the superuser is also already created
if [[ ! $(ls -A "$DATA_DIRECTORY") ]]; then
  echo "creating the data directory..."
  init_data_directory

  if [[ "$ROLE" != "slave" ]]; then
    echo "creating  superuser and template1..."
    create_superuser_and_template1 &
  fi
fi

sleep 2

if [[ ! -z "$AWS_ACCESS_KEY_ID" && ! -z "$AWS_S3_WALG_BUCKET_NAME" && ! -z "$AWS_SECRET_ACCESS_KEY" && ! -z "$BACKUP_EXECUTION_TIME" && "$ROLE" != "slave" ]]; then
  echo "start periodically backup at $BACKUP_EXECUTION_TIME""h..."
  periodically_backup &
fi

echo "starting postgresql..."
/usr/lib/postgresql/12/bin/postgres --config-file=etc/postgresql/12/main/postgresql.conf &

# wait for the pid of this file to end
wait $!
