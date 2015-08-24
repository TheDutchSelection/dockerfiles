# NAME: Varnish 4.0
#
# DESCRIPTION: Varnish image.
#
# REQUIRED ENVS:
# [APP]_[APP_ID]_HOST_PUBLIC_IP (ie. 123.123.123.1)
# [APP]_[APP_ID]_HOST_PORT (ie. 3000)
# [APP]_PROBE_PATH (ie. "/health_check/host", should be available on ip:port)
# [APP]_BACKEND_HOSTS (ie. "pcnltelecom.tdsapi.com pcnltelecom.tdscd.com")
# STORAGE_SIZE (ie. "20G", size varnish can use on disk)
#
# OPTIONAL ENVS:
# KEEP_CLIENT_COOKIES_AND_AUTH_PATHS (ie. "/contact /other-page-where-clients-needs-to-send-auth-or-cookies")
#
# OTHER:
# To use commands like varnishtop with docker exec, you have to run "export TERM=xterm" in the container first.


FROM thedutchselection/debian:8.1
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq apt-transport-https && \
  wget --quiet -O - https://repo.varnish-cache.org/GPG-key.txt | apt-key add - && \
  echo "deb https://repo.varnish-cache.org/debian/ wheezy varnish-4.0" > /etc/apt/sources.list.d/varnish-cache.list && \
  apt-get update && \
  useradd -m -u 6081 varnish && \
  apt-get install -yq varnish && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD files/scripts /usr/local/bin
ADD files/devicedetect.vcl /etc/varnish/devicedetect.vcl

RUN chmod +x /usr/local/bin/run.sh

EXPOSE 6081

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]