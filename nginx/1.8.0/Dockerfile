# NAME: Nginx 1.8.0
#
# DESCRIPTION: Nginx reverse proxy image.
#
# REQUIRED ENVS:
# WORKER_PROCESSES (ie. "2")
# WORKER_CONNECTIONS (ie. "1024")
# [APP]_[APP_ID]_HOST_PUBLIC_IP (ie. "81.192.5.1")
# [APP]_[APP_ID]_HOST_PORT (ie. "1001")
# SERVER_[APP]_DOMAIN (ie. "backend.thedutchselection.com")
# SERVER_[APP]_ROOT (ie. "/home/appmaster/application/public")
#
# OPTIONAL ENVS:
# SERVER_[APP]_ASSETS_DOMAIN (ie. "assets.thedutchselection.com")
# SERVER_[APP]_ASSETS_ROOT (ie. "/home/appmaster/application/public")
# SERVER_[APP]_LOCATION_OPTIONS (ie. "proxy_hide_header X-Frame-Options")
# SERVER_[APP]_ALLOW_ORIGIN (ie. "1")
# BASIC_AUTH_VALUES (ie. "username1##!!password1 username2##!!password2")
# SERVER_[APP]_IS_DEFAULT_SERVER (ie. "1")
#
# OTHER:

FROM thedutchselection/debian:8.1
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq libpcre3-dev && \
  apt-get install -yq libssl-dev && \
  apt-get install -yq zlib1g-dev && \
  apt-get install -yq libxslt1-dev && \
  apt-get install -yq libgd2-xpm-dev && \
  apt-get install -yq libgeoip-dev && \
  apt-get install -yq libperl-dev && \
  apt-get install -yq apache2-utils && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  useradd -m -u 6666 appmaster

ADD http://nginx.org/download/nginx-1.8.0.tar.gz /tmp/

WORKDIR /tmp

RUN \
  tar xvzf nginx-1.8.0.tar.gz && \
  cd nginx-1.8.0 && \
  ./configure \
    --prefix=/usr/local/nginx \
    --sbin-path=/usr/local/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/dev/null \
    --http-log-path=/dev/null \
    --pid-path=/run/nginx/nginx.pid \
    --lock-path=/run/lock/subsys/nginx \
    --user=nginx \
    --group=nginx \
    --with-file-aio \
    --with-ipv6 \
    --with-http_ssl_module \
    --with-http_spdy_module \
    --with-http_realip_module \
    --with-http_addition_module \
    --with-http_image_filter_module \
    --with-http_geoip_module \
    --with-http_sub_module \
    --with-http_dav_module \
    --with-http_mp4_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_random_index_module \
    --with-http_secure_link_module \
    --with-http_degradation_module \
    --with-http_stub_status_module \
    --with-http_perl_module \
    --with-pcre \
    --with-debug  \
    --without-http_scgi_module \
    --without-http_uwsgi_module \
    --without-http_fastcgi_module && \
  make && \
  make install && \
  rm -f /tmp/nginx-1.8.0.tar.gz && \
  rm -rf /tmp/nginx-1.8.0

ADD files/scripts /usr/local/bin

RUN \
  mkdir -p /etc/haproxy && \
  chmod +x /usr/local/bin/run.sh && \
  chown -R appmaster:appmaster /etc/nginx && \
  chown -R appmaster:appmaster /var/run/nginx && \
  chown -R appmaster:appmaster /usr/local/nginx && \
  chown -R appmaster:appmaster /usr/local/bin/*

EXPOSE 8080

USER appmaster

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
