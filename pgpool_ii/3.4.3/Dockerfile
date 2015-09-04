# NAME: Pgpool-II
#
# DESCRIPTION: Pgpool-II image.
#
# REQUIRED ENVS:
# BACKEND_DATA_DIRECTORY (ie. "/home/postgres/data/", this is the data directory on the postgresql container)
# DATA_DIRECTORY (ie. "/home/pgpool/data/")
# SWITCHABLE_IP (ie. "123.123.123.123")
# HEALTH_CHECK_USER (ie. "health_checker", user should exist in postgresql)
# HEALTH_CHECK_USER_PASSWORD (ie. "abcdabcd1234")
# HOST_IP (ie. "123.123.123.1", ip of the host this is running on)
# PGPOOL_[TYPE]_[APP_ID]_HOST_PUBLIC_IP (ie. "123.123.123.1")
# PGPOOL_[TYPE]_[APP_ID]_HOST_PORT_PEER (ie. "9694")
# POSTGRESQL_[TYPE]_[APP_ID]_HOST_PUBLIC_IP (ie. "123.123.123.1")
# POSTGRESQL_[TYPE]_[APP_ID]_HOST_PORT (ie. "5432")
# POSTGRESQL_[TYPE]_[APP_ID]_HOST_WEIGHT (ie. "1")
# POSTGRESQL_[TYPE]_[APP_ID]_HOST_FLAG (ie. "ALLOW_TO_FAILOVER", "ALLOW_TO_FAILOVER" or "DISALLOW_TO_FAILOVER")
# POSTGRESQL_USER_[ID] (ie. "user", all postgresql users need to be added)
# POSTGRESQL_PASSWORD_[ID] (ie. "abcdabcd1234")
# RECOVERY_USER (ie. "recoverer", user should exist in postgresql)
# RECOVERY_USER_PASSWORD (ie "abcdabcd1234")
# WATCHDOG_SWITCH_METHOD (ie. "hetzner")
# WATCHDOG_TRUSTED_SERVERS (ie. "123.123.123.123,234.234.234.234", to check if this pgpool is online)
#
# OPTIONAL ENVS:
# AWS_ACCESS_KEY_ID (ie. "FDEDFD3FDFD3AKHR3")
# AWS_S3_WALE_BUCKET_NAME (ie. "tds-app-backup")
# AWS_S3_WALE_BUCKET_PATH (ie. "postgresql/" ending with a slash)
# AWS_SECRET_ACCESS_KEY (ie. "yrthxdt45678oestwgsdf5es4trgd23")
# HETZNER_WEBSERVICE_PASSWORD (ie. "hetzner_api_password", only needed if WATCHDOG_SWITCH_METHOD is hetzner)
# HETZNER_WEBSERVICE_USERNAME (ie. "hetzner_api_user", only needed if WATCHDOG_SWITCH_METHOD is hetzner)
# PCP_PASSWORD (ie. "faer3wgrsear4regtds")
# PCP_USERNAME (ie. "pcp_user")
# WATCHDOG_AUTHKEY (ie. "bgerseawfsmkf", should be the same for all pgpools)
#
# OTHER: The WAL-E variables make online recovery possible through S3. This is the only way of online recovery
# implemented. So if the variables are left out, no online recovery is possible.
#
# Instructions to bring back a lost node:
# - Go inside a PGPool container "docker exec -it pgpool_ii bash".
# - Check which node is lost (status 3): "pcp_node_info --verbose 10000 localhost 9898 [pcp_username] [pcp_password] 1".
# - Make sure the postgresql container on the lost node is shut down and a new data container is up.
# - Bring the lost node back with "pcp_recovery_node -d 10000 localhost 9898 [pcp_username] [pcp_password] 1".
# - You have to manually bring the postgresql container back after this, see PostgreSQL dockerfile for instructions.


FROM thedutchselection/debian:8.1
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  apt-get update && \
  useradd -m -u 5432 postgres && \
  apt-get install -yq postgresql-client-9.4 && \
  apt-get install -yq postgresql-server-dev-9.4 && \
  apt-get install -yq arping && \
  apt-get install -yq net-tools && \
  apt-get install -yq libpq-dev && \
  apt-get install -yq curl && \
  apt-get install -yq lzop && \
  apt-get install -yq pv && \
  apt-get install -yq python && \
  apt-get install -yq python-dev && \
  apt-get install -yq nano && \
  apt-get install -yq libpgpool0 && \
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
  mkdir -p /etc/pgpool && \
  mkdir -p /var/run/pgpool && \
  mkdir -p /var/log/pgpool && \
  ln -s /bin/bash /sbin/bash && \
  rm -rf /tmp/*

ADD files/pcp_template.conf /etc/pgpool/
ADD files/pgpool_template.conf /etc/pgpool/
ADD files/pool_hba.conf /etc/pgpool/
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/pgpool/pcp_template.conf && \
  chmod 640 /etc/pgpool/pgpool_template.conf && \
  chmod 640 /etc/pgpool/pool_hba.conf && \
  chmod +x /usr/local/bin/run.sh && \
  chmod +x /usr/local/bin/copy_base_backup.sh && \
  chmod +x /usr/local/bin/pgpool_recovery_pitr.sh && \
  chmod +x /usr/local/bin/pgpool_remote_start && \
  chown -R postgres:postgres /etc/pgpool && \
  chown -R postgres:postgres /var/log/pgpool && \
  chown -R postgres:postgres /var/run/pgpool && \
  chown postgres:postgres /usr/local/bin/*

RUN \
  curl -O https://bootstrap.pypa.io/get-pip.py && \
  python get-pip.py && \
  rm get-pip.py && \
  pip install gevent==1.0.2 && \
  pip install boto==2.38.0 && \
  pip install wal-e==0.8.1

EXPOSE 9000
EXPOSE 9694
EXPOSE 9898
EXPOSE 9999

USER postgres

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
