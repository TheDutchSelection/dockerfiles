# NAME: Zyte Headless Proxy
#
# DESCRIPTION: Zyte Headless Proxy image to use with Zyte Smart Proxy Manager.
#
# REQUIRED ENVS:
# ZYTE_SPM_API_KEY (ie. "gdrt45hfe4t5", backend for app)
#
# OPTIONAL ENVS:
#
# OTHER:

FROM thedutchselection/alpine:3.15.0
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apk update && \
  apk add linux-headers && \
  apk add bash && \
  apk add ca-certificates && \
  apk add pcre-dev && \
  apk add zlib-dev && \
  apk add openssl-dev && \
  apk add g++ && \
  apk add busybox && \
  rm /var/cache/apk/* && \
  adduser -D -u 8080 zhp

ADD https://docs.zyte.com/_static/zyte-smartproxy-ca.crt /usr/local/share/ca-certificates/
ADD https://github.com/zytedata/zyte-smartproxy-headless-proxy/releases/download/1.3.2/crawlera-headless-proxy-linux-386 /usr/local/bin/crawlera-headless-proxy

RUN \
  update-ca-certificates && \
  mkdir -p /etc/zhp

WORKDIR /home/zhp

ADD files/config.toml /etc/zhp/
ADD files/scripts /usr/local/bin

RUN \
  chmod +x /usr/local/bin/run.sh && \
  chmod +rx /usr/local/bin/crawlera-headless-proxy && \
  chown -R zhp:zhp /etc/zhp && \
  chown zhp:zhp /usr/local/bin/*

EXPOSE 3128
EXPOSE 3130

USER zhp

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
