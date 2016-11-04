# NAME: Jenkins 2.19.2
#
# DESCRIPTION: Jenkins image.
#
# REQUIRED ENVS:
# DATA_DIRECTORY (ie. "/home/jenkins/data/")
#
# OPTIONAL ENVS:
# GIT_USER_NAME: (ie. "TDS Servers")
# GIT_USER_EMAIL: (ie. "github@tdsservers.com")
# REDIS_HOST (ie. 127.0.0.1)
# REDIS_PORT (ie. 6379)
# REDIS_DATABASE (ie. 0)
# REDIS_NAMESPACE (ie. "tds", : not allowed)
# REDIS_PASSWORD: (ie. "abcdabcd1234")
# SSH_KEY: (ie. "/home/jenkins/.ssh/id_rsa")
# SSH_PUB_KEY: (ie. "/home/jenkins/.ssh/id_rsa.pub")
#
# OTHER:
# mount the docker.sock from the host into this container for jenkins to be able to run docker commands, ie.
# -v /var/run/docker.sock:/var/run/docker.sock.
#
# The REDIS_ variables are needed for the deploy.sh script to communicate with redis and captain.

FROM thedutchselection/java:8
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  groupadd --gid 900 --system docker && \
  useradd -g docker -m -u 900 docker

RUN \
  echo "deb http://http.debian.net/debian jessie-backports main" > /etc/apt/sources.list.d/backports.list && \
  apt-get update && \
  apt-get install -yq apt-transport-https ca-certificates && \
  apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
  echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list && \
  apt-get update && \
  apt-get install -yq curl && \
  apt-get install -yq redis-tools && \
  apt-get install -yq docker-engine=1.10.3-0~jessie && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /opt/jenkins

WORKDIR /opt/jenkins

ADD http://mirrors.jenkins-ci.org/war-stable/2.19.2/jenkins.war /opt/jenkins/

RUN \
  useradd -m -u 8080 jenkins && \
  usermod -a -G docker jenkins && \
  usermod -a -G staff jenkins

ADD files/scripts /usr/local/bin

RUN \
  chmod +x /usr/local/bin/run.sh && \
  chown -R jenkins:jenkins /usr/local/bin/* && \
  chown -R jenkins:jenkins /opt/jenkins/*

EXPOSE 8080

ENTRYPOINT ["/bin/bash", "/usr/local/bin/run.sh"]
