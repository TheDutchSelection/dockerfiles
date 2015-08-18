#!/bin/bash
set -e

# description: init the data directory and create the superuser
init_data_directory() {
  # if old data directory exist, we asume that everything below has already been done
  if [[ ! $(ls -A "$old_data_directory") ]]; then
    echo "moving old data from $DATA_DIRECTORY to $old_data_directory ..."
    mkdir -p "$old_data_directory"
    mv_directory="$DATA_DIRECTORY""/*"
    mv $mv_directory "$old_data_directory"
    chmod 700 $old_data_directory

    echo "initializing $DATA_DIRECTORY..."
    cp -R /var/lib/postgresql/9.4/main/* "$DATA_DIRECTORY"
  fi
}

# remove any existing postgresql pid
rm -f /run/postgresql/*

echo "copy postgresql.conf file..."
cp -p /etc/postgresql/9.3/main/postgresql_9_3_template.conf /etc/postgresql/9.3/main/postgresql.conf
cp -p /etc/postgresql/9.4/main/postgresql_9_4_template.conf /etc/postgresql/9.4/main/postgresql.conf

old_data_directory="/tmp/old_data"
escaped_data_directory=${DATA_DIRECTORY//\//\\\/}
escaped_old_data_directory=${old_data_directory//\//\\\/}

echo "set values to postgresql.conf file..."
sed -i "s/##data_directory##/$escaped_old_data_directory/g" /etc/postgresql/9.3/main/postgresql.conf
sed -i "s/##data_directory##/$escaped_data_directory/g" /etc/postgresql/9.4/main/postgresql.conf

init_data_directory

echo "starting upgrade process..."
cd /tmp
/usr/lib/postgresql/9.4/bin/pg_upgrade \
-b /usr/lib/postgresql/9.3/bin \
-B /usr/lib/postgresql/9.4/bin \
-d $old_data_directory \
-D $DATA_DIRECTORY \
-o "-c config_file=/etc/postgresql/9.3/main/postgresql.conf" \
-O "-c config_file=/etc/postgresql/9.4/main/postgresql.conf"
