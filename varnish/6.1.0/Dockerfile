# NAME: Varnish 6.1.0
#
# DESCRIPTION: Varnish image.
#
# REQUIRED ENVS:
# [APP]_[APP_ID]_HOST_PUBLIC_IP (ie. 123.123.123.1)
# [APP]_[APP_ID]_HOST_PORT (ie. 3000)
# [APP]_PROBE_PATH (ie. "/health_check/host", should be available on ip:port)
# [APP]_BACKEND_HOSTS (ie. "pcnltelecom.tdsapi.com pcnltelecom.tdscd.com")
# LONG_TERM_CLIENT_CACHE_MATCHES (ie. "tdscd.com other-asset-domain.com")
# STORAGE_SIZE (ie. "20G", size varnish can use on disk)
#
# OPTIONAL ENVS:
#
# OTHER:
# Some commands:
# varnishtop -i BereqURL (urls that most hit the backend)
# varnishlog -q 'ReqURL ~ "^/foo/bar"' (request coming from the client containing /foo/bar
# varnishstat (statistics about varnish)
# varnishadm backend.list (backend status)


FROM thedutchselection/debian:9.5
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq debian-archive-keyring && \
  apt-get install -yq apt-transport-https && \
  apt-get install -yq curl && \
  apt-get install -yq gnupg && \
  curl -L https://packagecloud.io/varnishcache/varnish61/gpgkey | apt-key add - && \
  echo "deb https://packagecloud.io/varnishcache/varnish61/debian/ stretch main" > /etc/apt/sources.list.d/varnish-cache.list && \
  echo "deb-src https://packagecloud.io/varnishcache/varnish61/debian/ stretch main" >> /etc/apt/sources.list.d/varnish-cache.list && \
  apt-get update && \
  useradd -m -u 6081 varnish && \
  apt-get install -yq varnish=6.1.0-1~stretch && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD files/scripts /usr/local/bin

RUN chmod +x /usr/local/bin/run.sh

ENV TERM xterm

EXPOSE 6081

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
