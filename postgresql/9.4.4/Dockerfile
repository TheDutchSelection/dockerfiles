# NAME: PostgreSQL 9.4.4
#
# DESCRIPTION: PostgreSQL image.
#
# REQUIRED ENVS:
# DATA_DIRECTORY (ie. "/home/postgres/data/")
#
# OPTIONAL ENVS:
# AWS_ACCESS_KEY_ID (ie. "FDEDFD3FDFD3AKHR3")
# AWS_S3_WALE_BUCKET_NAME (ie. "tds-app-backup")
# AWS_S3_WALE_BUCKET_BASE_PATH (ie. "postgresql/" ending with a slash)
# AWS_SECRET_ACCESS_KEY (ie. "yrthxdt45678oestwgsdf5es4trgd23")
# BACKUP_EXECUTION_TIME (ie. "02:00", time is in UTC and for backups to succeed, WALE needs to be setup)
# HOST_IP (ie. "123.123.123.1", ip of the host this is running on, if use_with_pgpool or WAL-E)
# RUN_AS_DEVELOPMENT (ie. "1", if set the database will be insecure)
# SUPERUSER_USERNAME (ie. "superuser")
# SUPERUSER_PASSWORD (ie. "abcdabcd1234")
# USE_WITH_PGPOOL (ie. "1", if set template1 will be prepared for pgpool-ii)
#
# OTHER:
# PGPool II is also installed to be able to use the functions it comes with for Postgresql. PGPool itself is not to be
# used from this image. The WAL-E variables activate archiving to S3 (archiving will otherwise be off)
#
# Instructions for recovery using wale:
# - Make sure PostgreSQL container is not running, "systemctl disable postgresql_master", "systemctl stop postgresql_master"
# - Throw away current data container "docker rm postgresql_master_data"
# - Create new data container "systemctl enable [path-to]/postgresql_master", "systemctl start postgresql_master"
# - Stop PostgreSQL again "systemctl disable postgresql_master", "systemctl stop postgresql_master"
# - Start a container to execute backup commands "docker run -it --rm --entrypoint="bash" --volumes-from postgresql_master_data thedutchselection/postgresql:9.4.4"
# - Set the following envs (export AWS_ACCESS_KEY_ID="") DATA_DIRECTORY, AWS_ACCESS_KEY_ID, AWS_S3_WALE_BUCKET_NAME,
#   AWS_S3_WALE_BUCKET_BASE_PATH, AWS_SECRET_ACCESS_KEY, HOST_IP (this has to be the ip of the server that servers as current master)
# - Run "wal-e --s3-prefix=s3://tds-database-backups/"$HOST_IP" backup-fetch "$DATA_DIRECTORY" LATEST"
# - Run "echo "restore_command = 'wal-e --s3-prefix=s3://tds-database-backups/"$HOST_IP" wal-fetch %f %p'" > "$DATA_DIRECTORY""recovery.conf""
# - Exit this container.
# - Remove (inconsistent) S3 wal-e data for this PostgreSQL.
# - Start PostgreSQL "systemctl enable [path-to]/postgresql_master", "systemctl start postgresql_master" and everything should run fine.


FROM thedutchselection/debian:8.1
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  apt-get update && \
  apt-get install -yq python-software-properties && \
  apt-get install -yq software-properties-common && \
  useradd -m -u 5432 postgres && \
  apt-get install -yq postgresql-9.4 && \
  apt-get install -yq postgresql-client-9.4 && \
  apt-get install -yq postgresql-contrib-9.4 && \
  apt-get install -yq postgresql-server-dev-9.4 && \
  apt-get install -yq curl && \
  apt-get install -yq lzop && \
  apt-get install -yq pv && \
  apt-get install -yq python && \
  apt-get install -yq python-dev && \
  apt-get install -yq inotify-tools && \
  apt-get install -yq psmisc && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD http://www.pgpool.net/download.php?f=pgpool-II-3.4.3.tar.gz /tmp/pgpool-II-3.4.3.tar.gz

WORKDIR /tmp

RUN \
  tar -xzf pgpool-II-3.4.3.tar.gz && \
  cd pgpool-II-3.4.3 && \
  ./configure && \
  make && \
  make install && \
  cd /tmp/pgpool-II-3.4.3/src/sql/pgpool-regclass && \
  make && \
  make install && \
  cd /tmp/pgpool-II-3.4.3/src/sql/pgpool-recovery && \
  make && \
  make install && \
  cp -R /tmp/pgpool-II-3.4.3/src/sql/* /usr/local/share/pgpool-II/ && \
  rm -rf /tmp/*

RUN \
  curl -O https://bootstrap.pypa.io/get-pip.py && \
  python get-pip.py && \
  rm get-pip.py && \
  pip install gevent==1.0.2 && \
  pip install boto==2.38.0 && \
  pip install wal-e==0.8.1

ADD files/pg_hba_template.conf /etc/postgresql/
ADD files/pg_ident.conf /etc/postgresql/
ADD files/postgresql_template.conf /etc/postgresql/
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/postgresql/pg_hba_template.conf && \
  chmod 640 /etc/postgresql/pg_ident.conf && \
  chmod 644 /etc/postgresql/postgresql_template.conf && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R postgres:postgres /etc/postgresql && \
  chown postgres:postgres /usr/local/bin/*

EXPOSE 5432

USER postgres

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
