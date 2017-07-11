# NAME: PG Admin 4
#
# DESCRIPTION: PG Admin 4.
#
# REQUIRED ENVS:
# WORKER_PROCESSES (ie. "2")
# WORKER_CONNECTIONS (ie. "1024")
#
# OPTIONAL ENVS:
# DEFAULT_USER (ie. "test@thedutchselection.com", default: "pgadmin4@pgadmin.org")
# DEFAULT_PASSWORD (ie. "abcdabcd1234", default: "admin")
# MAIL_PASSWORD (ie. "abcd", default: none)
# MAIL_PORT (ie. "2525", default: "25"
# MAIL_SERVER (ie. "smtp.example.com", default: "localhost"
# MAIL_USE_SSL (ie. "true", default: "false")
# MAIL_USE_TLS (ie. "true", default: "false"
# MAIL_USERNAME (ie. "test", default: none)
#
# OTHER:

FROM python:3-alpine
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

ENV PGADMIN4_VERSION 1.5

RUN set -ex \
	&& apk add --no-cache --virtual .run-deps \
		bash \
		postgresql-libs \
	&& apk add --no-cache --virtual .build-deps \
		openssl \
		gcc \
		postgresql-dev \
		musl-dev \
	&& wget "https://ftp.postgresql.org/pub/pgadmin/pgadmin4/v$PGADMIN4_VERSION/pip/pgadmin4-$PGADMIN4_VERSION-py2.py3-none-any.whl" \
	&& pip install pgadmin4-$PGADMIN4_VERSION-py2.py3-none-any.whl \
	&& apk del .build-deps \
	&& rm pgadmin4-$PGADMIN4_VERSION-py2.py3-none-any.whl \
	&& rm -rf /root/.cache

VOLUME /var/lib/pgadmin4

ADD files/scripts /usr/local/bin

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]

EXPOSE 5050
CMD ["pgadmin4"]