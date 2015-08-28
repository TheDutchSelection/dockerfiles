#!/bin/bash
set -e

trap "echo \"Sending SIGTERM to processes\"; killall -s SIGTERM -w postgres" SIGTERM

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

  if [[ "$USE_WITH_PGPOOL" == "1" ]]; then
    local authentication_setting_3=${authentication_setting//\#\#type\#\#/"host"}
    local authentication_setting_3=${authentication_setting_3//\#\#database\#\#/"replication"}
    local authentication_setting_3=${authentication_setting_3//\#\#user\#\#/"all"}
    local authentication_setting_3=${authentication_setting_3//\#\#address\#\#/"0.0.0.0/0"}
    local authentication_setting_3=${authentication_setting_3//\#\#auth_method\#\#/"md5"}

    local authentication_setting_4=${authentication_setting_1//0\.0\.0\.0\/0/"::1/128"}
  fi

  local authentication_settings="$authentication_setting_1"$'\n'"$authentication_setting_2"$'\n'"$authentication_setting_3"$'\n'"$authentication_setting_4"$'\n'

  echo "$authentication_settings"
}

create_postgresql_conf () {
  set -e

  local escaped_data_directory=$(escape_string "$DATA_DIRECTORY")

  sed -i "s/##data_directory##/$escaped_data_directory/g" /etc/postgresql/postgresql.conf
  if [[ ! -z "$AWS_S3_WALE_ACCESS_KEY_ID" && ! -z "$AWS_S3_WALE_BUCKET_NAME" && ! -z "$AWS_S3_WALE_SECRET_ACCESS_KEY" ]]; then
    # set environment variables matching WAL-E preferences
    AWS_ACCESS_KEY_ID="$AWS_S3_WALE_ACCESS_KEY_ID"
    AWS_SECRET_ACCESS_KEY="$AWS_S3_WALE_SECRET_ACCESS_KEY"
    if [[ -z "$AWS_S3_WALE_BUCKET_BASE_PATH" || "$AWS_S3_WALE_BUCKET_BASE_PATH" == "/" ]]; then
      WALE_S3_PREFIX="\"s3://""$AWS_S3_WALE_BUCKET_NAME""/""$HOST_IP""\""
    else
      WALE_S3_PREFIX="\"s3://""$AWS_S3_WALE_BUCKET_NAME""/""$AWS_S3_WALE_BUCKET_BASE_PATH""$HOST_IP""\""
    fi
    export "$AWS_ACCESS_KEY_ID"
    export "$AWS_SECRET_ACCESS_KEY"
    export "$WALE_S3_PREFIX"

    local archive_mode="on"
    local archive_command="wal-e wal-push %p"
  else
    local archive_mode="off"
    local archive_command=""
  fi
  sed -i "s/##archive_mode##/$archive_mode/g" /etc/postgresql/postgresql.conf
  sed -i "s/##archive_command##/$archive_command/g" /etc/postgresql/postgresql.conf
}

# description: init the data directory and create the superuser
init_data_directory_and_create_superuser() {
  # if data directory exist, we asume the superuser is also already created and the pgpool sql has been applied
  if [[ ! $(ls -A "$DATA_DIRECTORY") ]]; then
    echo "initializing $DATA_DIRECTORY..."
    mkdir -p "$DATA_DIRECTORY"
    cp -R /var/lib/postgresql/9.4/main/* "$DATA_DIRECTORY"

    # wait for postgresql to start
    echo "waiting for postgresql to be started..."
    while [[ ! -e /run/postgresql/9.4-main.pid ]] ; do
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

    if [[ "$USE_WITH_PGPOOL" == "1" ]]; then
      echo "applying pgpool-regclass sql to template1"
      psql -f /usr/local/share/pgpool-II/pgpool-regclass/pgpool-regclass.sql template1

      echo "applying insert_lock sql to template1"
      psql -f /usr/local/share/pgpool-II/insert_lock.sql template1

      echo "applying pgpool-recovery sql to template1"
      psql -f /usr/local/share/pgpool-II/pgpool-recovery/pgpool-recovery.sql template1
    fi

    echo "vacuum freeze template1..."
    psql -q <<-EOF
      \c template1
      VACUUM FREEZE;
EOF

  fi
}

# remove any existing postgresql pid
rm -f /run/postgresql/*

echo "copy conf files.."
cp -p /etc/postgresql/postgresql_template.conf /etc/postgresql/postgresql.conf
cp -p /etc/postgresql/pg_hba_template.conf /etc/postgresql/pg_hba.conf

echo "set values to postgresql.conf file..."
create_postgresql_conf

echo "set values to pg_hba.conf..."
authentication_settings=$(create_authentication_settings)
escaped_authentication_settings=$(escape_string "$authentication_settings")
perl -i -pe 's/##authentication_settings##/'"${escaped_authentication_settings}"'/g' /etc/postgresql/pg_hba.conf

init_data_directory_and_create_superuser &

sleep 2

echo "starting postgresql..."
/usr/lib/postgresql/9.4/bin/postgres -c config_file=/etc/postgresql/postgresql.conf &

# wait for the pid of this file to end
wait $!
