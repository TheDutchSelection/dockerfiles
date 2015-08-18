# NAME: PostgreSQL 9.4.4
#
# DESCRIPTION: PostgreSQL image.
#
# REQUIRED ENVS:
# DATA_DIRECTORY (ie. "/home/postgresql/data/")
#
# OPTIONAL ENVS:
# RUN_AS_DEVELOPMENT (ie. "1", if set the database will be insecure)
# SUPERUSER_USERNAME (ie. "superuser")
# SUPERUSER_PASSWORD (ie. "abcdabcd1234")
#
# OTHER:


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
  apt-get install -yq inotify-tools && \
  apt-get install -yq psmisc && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD files/pg_hba_template.conf /etc/postgresql/9.4/main/
ADD files/pg_ident.conf /etc/postgresql/9.4/main/
ADD files/postgresql_template.conf /etc/postgresql/9.4/main/
ADD files/scripts /usr/local/bin

RUN \
  chmod 640 /etc/postgresql/9.4/main/pg_hba_template.conf && \
  chmod 640 /etc/postgresql/9.4/main/pg_ident.conf && \
  chmod 644 /etc/postgresql/9.4/main/postgresql_template.conf && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R postgres:postgres /etc/postgresql/9.4/main && \
  chown postgres:postgres /usr/local/bin/*

EXPOSE 5432

USER postgres

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
