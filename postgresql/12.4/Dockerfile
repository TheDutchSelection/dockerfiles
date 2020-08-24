# NAME: PostgreSQL 12.4
#
# DESCRIPTION: PostgreSQL image.
#
# REQUIRED ENVS:
# DATA_DIRECTORY (ie. "/home/postgres/data/")
#
# OPTIONAL ENVS:
# AWS_ACCESS_KEY_ID (ie. "FDEDFD3FDFD3AKHR3", needed if Wal-G is used)
# AWS_REGION (ie. "eu-west-1", region of the backup bucket, needed if Wal-G is used)
# AWS_S3_WALG_BUCKET_NAME (ie. "tds-app-backup", needed if Wal-G is used)
# AWS_SECRET_ACCESS_KEY (ie. "yrthxdt45678oestwgsdf5es4trgd23", needed if Wal-G is used)
# BACKUP_EXECUTION_TIME (ie. "02:00", time is in UTC and for backups to succeed, Wal-G needs to be setup)
# BACKUP_HOST_IP (ie. "123.123.123.1", ip of the "other" (slave if this is master and vice versa) host, needed if Wal-G is used)
# HOST_IP (ie. "123.123.123.1", ip of the host this is running on, needed if Wal-G is used)
# MASTER_HOST_IP (ie. "123.123.123.1", ip of the master, needed if ROLE=slave)
# MASTER_HOST_PORT (ie. "5432", port of the master, needed if ROLE=slave)
# MAX_CONNECTIONS (ie. "100", defaults to 500)
# MAX_REPLICATION_SLOTS (ie. "5", defaults to 0, needed if you want replication)
# MAX_WAL_SENDERS (ie. "5", defaults to 0, no replication, needed if you want replication)
# REPLICATOR_PASSWORD (ie. "rep", replicator password, needed if ROLE=slave)
# REPLICATOR_USER (ie. "rep", replicator user, needed if ROLE=slave)
# ROLE (ie. "master", master or slave, default is master)
# RUN_AS_DEVELOPMENT (ie. "1", if set the database will be insecure)
# SHARED_BUFFERS (ie. "16", means 16GB, default is 1)
# SUPERUSER_USERNAME (ie. "superuser")
# SUPERUSER_PASSWORD (ie. "abcdabcd1234")
#
# OTHER:
# The Wal-G variables activate archiving to S3 (archiving will otherwise be off)
#
#
# PROMOTING A SLAVE TO MASTER
# - Set the failover ip to the server of the slave you want to promote to master
# - Ssh to the slave server you want to promote "docker exec -it postgresql_slave bash"
# - Run "touch "$DATA_DIRECTORY""failover.signal""
# - This slave is now accepting write connections and acting as the master, it will not try to connect to the previous master
#
#
# REINSTATING THE PREVIOUS MASTER
# - Set the failover ip to the master server
# - Go to the slave server and do "docker exec -it postgresql_slave bash"
# - Run "wal-g backup-push "$DATA_DIRECTORY" --pghost="/var/run/postgresql" --walg-s3-prefix=s3://tds-database-backups/"$HOST_IP""
# - Run "sudo systemctl disable postgresql_slave && sudo systemctl stop postgresql_slave && docker rm -v postgresql_slave"
# - Go to the master server and follow "DATA RECOVERY USING WAL-G"
# - When everything is up and running follow "SLAVE SERVER THAT IS OUT OF SYNC" to reinstate the slave server
# - Remove S3 wal-g data from S3 for the slave server.
# - Everything is back to normal
#
#
# DATA RECOVERY USING WAL-G (WRITTEN FOR MASTER)
# - Make sure PostgreSQL container is not running, "sudo systemctl disable postgresql_master && sudo systemctl stop postgresql_master && docker rm -v postgresql_master"
# - Throw away current data directory "sudo rm -rf /var/lib/data/container_data/postgresql_master/data"
# - Create the data directory again "sudo mkdir -m 700 /var/lib/data/container_data/postgresql_master/data"
# - Give the data directory the right ownership and permissions "sudo chown -R 5432:5432 /var/lib/data/container_data/postgresql_master/data"
# - Start a container to execute backup commands:
#     /usr/bin/docker run \
#     -it --rm \
#     -e "AWS_ACCESS_KEY_ID=[access key]" \
#     -e "AWS_REGION=[region]" \
#     -e "AWS_S3_WALG_BUCKET_NAME=[bucket name]" \
#     -e "AWS_SECRET_ACCESS_KEY=[aws secret access key]" \
#     -e "BACKUP_HOST_IP=[slave host ip]" \
#     -e "DATA_DIRECTORY=/home/postgres/data/" \
#     -e "HOST_IP=[host ip]" \
#     -e "ROLE=master" \
#     -v /var/lib/data/container_data/postgresql_master/data:/home/postgres/data/ \
#     --entrypoint=bash \
#     thedutchselection/postgresql:12.4
# If recovering from slave:
# - Run "wal-g --walg-s3-prefix=s3://tds-database-backups/"$BACKUP_HOST_IP" backup-fetch "$DATA_DIRECTORY" LATEST" (you can also change LATEST to a backup name ie. base_0000000200000001000000FF_00000040)
# If recovering from master:
# - Run "wal-g --walg-s3-prefix=s3://tds-database-backups/"$HOST_IP" backup-fetch "$DATA_DIRECTORY" LATEST" (you can also change LATEST to a backup name ie. base_0000000200000001000000FF_00000040)
# - Copy the postgresql_template.conf to postgresql.conf "cp -p /etc/postgresql/12/main/postgresql_template.conf /etc/postgresql/12/main/postgresql.conf"
# - Edit this file with nano and replace all ## value:
#     data_directory = '/home/postgres/data/'
#     max_connections = 500
#     shared_buffers = 16GB
#     archive_mode = off
#     # archive_command
#     restore_command = 'wal-g wal-fetch %f %p --pghost=/var/run/postgresql/ --walg-s3-prefix s3://[bucket name]/[ip of the host you want to restore from]'
#     recovery_target = 'immediate'
#     recovery_target_time = '' <-- only if doing a point in time recovery. Can contain something like '2016-02-19 15:50:00 GMT'
#     # max_wal_senders
#     # max_replication_slots
#     # primary_conninfo
#     # promote_trigger_file
#     hot_standby = off
# - Run "touch "$DATA_DIRECTORY""recovery.signal""
# - Run "/usr/lib/postgresql/12/bin/postgres --config-file=etc/postgresql/12/main/postgresql.conf"
# - This process should stop when recovery is done.
# - Run "rm "$DATA_DIRECTORY""recovery.signal""
# - Exit this container.
# - Remove S3 wal-g data from S3 for this PostgreSQL.
# - Start PostgreSQL "sudo systemctl enable /etc/systemd/user/postgresql_master.service && sudo systemctl start postgresql_master" and everything should run fine.
#
#
# REPLICATION STATUS ON THE SLAVE SERVER
# - Do "docker exec -it postgresql_slave bash"
# - Do "psql"
# - Execute the query "select now() - pg_last_xact_replay_timestamp() AS replication_delay;"
# This gives the replication delay. If there are no writes to the master, this might be bigger without any problems.
#
#
# SLAVE SERVER THAT IS OUT OF SYNC
# - Make sure PostgreSQL slave container is not running, "sudo systemctl disable postgresql_slave && sudo systemctl stop postgresql_slave && docker rm -v postgresql_slave"
# - Throw away current data directory "sudo rm -rf /var/lib/data/container_data/postgresql_slave/data"
# - Create the data directory again "sudo mkdir -m 700 /var/lib/data/container_data/postgresql_slave/data"
# - Give the data directory the right ownership and permissions "sudo chown -R 5432:5432 /var/lib/data/container_data/postgresql_slave/data"
# - Start the PostgreSQL slave container again "sudo systemctl enable /etc/systemd/user/postgresql_slave.service && sudo systemctl start postgresql_slave"

FROM thedutchselection/debian:10.4
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ buster-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  apt-get update && \
  apt-get install -yq software-properties-common && \
  useradd -m -u 5432 postgres && \
  apt-get install -yq postgresql-12=12.4-1.pgdg100+1 && \
  apt-get install -yq postgresql-client-12=12.4-1.pgdg100+1 && \
  apt-get install -yq postgresql-server-dev-12=12.4-1.pgdg100+1 && \
  apt-get install -yq curl && \
  apt-get install -yq lzop && \
  apt-get install -yq pv && \
  apt-get install -yq inotify-tools && \
  apt-get install -yq psmisc && \
  apt-get install -yq nano && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
  wget https://github.com/wal-g/wal-g/releases/download/v0.2.16/wal-g.linux-amd64.tar.gz && \
  tar -zxvf wal-g.linux-amd64.tar.gz && \
  rm wal-g.linux-amd64.tar.gz && \
  mv wal-g /usr/local/bin/ && \
  chown -R postgres:postgres /usr/local/bin/wal-g && \
  chmod 740 /usr/local/bin/wal-g

ADD files/pg_hba_template.conf /etc/postgresql/12/main/
ADD files/postgresql_template.conf /etc/postgresql/12/main/
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/postgresql/12/main/pg_hba_template.conf && \
  chmod 644 /etc/postgresql/12/main/postgresql_template.conf && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R postgres:postgres /etc/postgresql/12/main && \
  chown postgres:postgres /usr/local/bin/*

EXPOSE 5432

USER postgres

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
