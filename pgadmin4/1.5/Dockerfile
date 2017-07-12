# NAME: PG Admin 4
#
# DESCRIPTION: PG Admin 4.
#
# REQUIRED ENVS:
# DEFAULT_USER (ie. "test@thedutchselection.com")
# DEFAULT_PASSWORD (ie. "abcdabcd1234")
#
# OPTIONAL ENVS:
#
# OTHER:
#
# Usage: docker run -d --name pgadmin4 -p 5050:5050 -e "DEFAULT_USER=pgadmin4" -e "DEFAULT_USER=admin1*" thedutchselection/pgadmin4:1.5

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