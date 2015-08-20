#!/bin/bash
set -e

trap "echo \"Sending SIGTERM to processes\"; killall -s SIGTERM -w postgres" SIGTERM

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

echo "copy postgresql.conf file..."
cp -p /etc/postgresql/9.4/main/postgresql_template.conf /etc/postgresql/9.4/main/postgresql.conf
cp -p /etc/postgresql/9.4/main/pg_hba_template.conf /etc/postgresql/9.4/main/pg_hba.conf

escaped_data_directory=${DATA_DIRECTORY//\//\\\/}

echo "set values to postgresql.conf file..."
sed -i "s/##data_directory##/$escaped_data_directory/g" /etc/postgresql/9.4/main/postgresql.conf
if [[ "$RUN_AS_DEVELOPMENT" == "1" ]]; then
  sed -i "s/##user_auth_method##/trust/g" /etc/postgresql/9.4/main/pg_hba.conf
else
  sed -i "s/##user_auth_method##/md5/g" /etc/postgresql/9.4/main/pg_hba.conf
fi

init_data_directory_and_create_superuser &

echo "starting postgresql..."
/usr/lib/postgresql/9.4/bin/postgres -c config_file=/etc/postgresql/9.4/main/postgresql.conf &

# wait for the pid of this file to end
wait $!
