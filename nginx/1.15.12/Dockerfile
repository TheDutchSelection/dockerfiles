# NAME: Nginx 1.15.12
#
# DESCRIPTION: Nginx reverse proxy image.
#
# REQUIRED ENVS:
# WORKER_PROCESSES (ie. "2")
# WORKER_CONNECTIONS (ie. "1024")
#
# OPTIONAL ENVS:
# [APP]_[APP_ID]_HOST_PUBLIC_IP (ie. "81.192.5.1")
# [APP]_[APP_ID]_HOST_PORT (ie. "1001")
# SERVER_[APP]_DOMAIN (ie. "backend.thedutchselection.com")
# SERVER_[APP]_IS_DEFAULT_SERVER (ie. "1")
# SERVER_[APP]_LOCATION_OPTIONS (ie. "proxy_hide_header X-Frame-Options")
# SERVER_[APP]_REDIRECTS (ie. "^/pc-inpage.js\$!!##/assets/js/main-42345jsdfg.js ^/pc-inpage.css\$!!##/assets/css/main-42345jsdfg.css")
# SERVER_[APP]_ROOT (ie. "/home/appmaster/application/public")
# SERVER_[APP]_TYPE ("proxy", "standard")
# BASIC_AUTH_VALUES (ie. "username1!!##password1 username2!!##password2")
#
# OTHER:

FROM thedutchselection/alpine:3.11.3
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apk update && \
  apk add linux-headers && \
  apk add bash && \
  apk add make && \
  apk add pcre-dev && \
  apk add zlib-dev && \
  apk add openssl-dev && \
  apk add musl && \
  apk add libressl && \
  apk add g++ && \
  apk add apache2-utils && \
  rm /var/cache/apk/* && \
  adduser -D -u 6666 appmaster

ADD http://nginx.org/download/nginx-1.15.12.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar xvzf nginx-1.15.12.tar.gz && \
  cd nginx-1.15.12 && \
  ./configure \
    --prefix=/usr/local/nginx \
    --sbin-path=/usr/local/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/dev/null \
    --http-log-path=/dev/null \
    --pid-path=/var/run/nginx/nginx.pid \
    --lock-path=/var/run/lock/subsys/nginx \
    --user=nginx \
    --group=nginx \
    --with-file-aio \
    --with-ipv6 \
    --with-http_ssl_module \
    --with-http_v2_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_secure_link_module \
    --with-http_degradation_module \
    --with-http_stub_status_module \
    --with-pcre \
    --with-debug \
    --without-http_scgi_module \
    --without-http_uwsgi_module \
    --without-http_fastcgi_module && \
  make && \
  make install && \
  mkdir -p /var/run/nginx && \
  mkdir -p /var/run/lock/subsys && \
  rm -f /tmp/nginx-1.15.12.tar.gz && \
  rm -rf /tmp/nginx-1.15.12

WORKDIR /home/appmaster

ADD files/scripts /usr/local/bin

RUN \
  mkdir -p /etc/nginx && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R appmaster:appmaster /etc/nginx && \
  chown -R appmaster:appmaster /var/run/nginx && \
  chown -R appmaster:appmaster /var/run/lock/subsys && \
  chown -R appmaster:appmaster /usr/local/nginx && \
  chown -R appmaster:appmaster /usr/local/bin/*

EXPOSE 8080

USER appmaster

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
