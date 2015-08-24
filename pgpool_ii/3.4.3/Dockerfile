# NAME: Pgpool-II
#
# DESCRIPTION: Pgpool-II image.
#
# REQUIRED ENVS:
# DATA_DIRECTORY (ie. "/home/pgpool/data/")
# DELEGATE_IP (ie. "123.123.123.123")
# HEALTH_CHECK_USER (ie. "health_checker", user should exist in postgresql)
# HEALTH_CHECK_USER_PASSWORD (ie. "abcdabcd1234")
# HOST_IP (ie. "123.123.123.1", ip of the host this is running on)
# PGPOOL_[TYPE]_[APP_ID]_HOST_PUBLIC_IP (ie. "123.123.123.1")
# PGPOOL_[TYPE]_[APP_ID]_HOST_PORT_PEER (ie. "9694")
# POSTGRESQL_[TYPE]_[APP_ID]_HOST_PUBLIC_IP (ie. "123.123.123.1")
# POSTGRESQL_[TYPE]_[APP_ID]_HOST_PORT (ie. "5432")
# POSTGRESQL_[TYPE]_[APP_ID]_HOST_WEIGHT (ie. "1")
# POSTGRESQL_[TYPE]_[APP_ID]_HOST_FLAG (ie. "ALLOW_TO_FAILOVER", "ALLOW_TO_FAILOVER" or "DISALLOW_TO_FAILOVER")
# RECOVERY_USER (ie. "recoverer", user should exist in postgresql)
# RECOVERY_USER_PASSWORD (ie "abcdabcd1234")
# WATCHDOG_SWITCH_METHOD (ie. "hetzner")
# WATCHDOG_TRUSTED_SERVERS (ie. "123.123.123.123,234.234.234.234", to check if this pgpool is online)
#
# OPTIONAL ENVS:
# HETZNER_WEBSERVICE_PASSWORD (ie. "hetzner_api_password", only needed if WATCHDOG_SWITCH_METHOD is hetzner)
# HETZNER_WEBSERVICE_USERNAME (ie. "hetzner_api_user", only needed if WATCHDOG_SWITCH_METHOD is hetzner)
# PCP_PASSWORD (ie. "faer3wgrsear4regtds")
# PCP_USERNAME (ie. "pcp_user")
# WATCHDOG_AUTHKEY (ie. "bgerseawfsmkf", should be the same for all pgpools)
#
# OTHER:

FROM thedutchselection/debian:8.1
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
  echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  apt-get update && \
  apt-get install -yq postgresql-client-9.4 && \
  apt-get install -yq postgresql-server-dev-9.4 && \
  apt-get install -yq arping && \
  apt-get install -yq net-tools && \
  apt-get install -yq libpq-dev && \
  useradd -m -u 9999 pgpool && \
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
  ln -s /bin/bash /sbin/bash && \
  rm -rf /tmp/*

ADD files/pcp_template.conf /etc/pgpool/
ADD files/pgpool_template.conf /etc/pgpool/
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/pgpool/pcp_template.conf && \
  chmod 640 /etc/pgpool/pgpool_template.conf && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R pgpool:pgpool /etc/pgpool && \
  chown -R pgpool:pgpool /var/run/pgpool && \
  chown pgpool:pgpool /usr/local/bin/*

EXPOSE 9000
EXPOSE 9694
EXPOSE 9898
EXPOSE 9999

USER pgpool

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
