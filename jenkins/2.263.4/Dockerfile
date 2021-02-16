# NAME: Jenkins 2.263.4
#
# DESCRIPTION: Jenkins image.
#
# REQUIRED ENVS:
# CAPTAIN_HOST_PUBLIC_IP (ie. 10.0.0.1)
# CAPTAIN_HOST_PORT (ie. 1001)
# DATA_DIRECTORY (ie. "/home/jenkins/data/")
#
# OPTIONAL ENVS:

# SSH_KEY: (ie. "/home/jenkins/.ssh/id_rsa")
# SSH_PUB_KEY: (ie. "/home/jenkins/.ssh/id_rsa.pub")
#
# OTHER:
# mount the docker.sock from the host into this container for jenkins to be able to run docker commands, ie.
# -v /var/run/docker.sock:/var/run/docker.sock.

FROM thedutchselection/java:11
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  groupadd --gid 900 --system docker && \
  useradd -g docker -m -u 900 docker

RUN \
  echo "deb http://http.debian.net/debian buster-backports main" > /etc/apt/sources.list.d/backports.list && \
  apt-get update && \
  apt-get install -yq apt-transport-https && \
  apt-get install -yq ca-certificates && \
  apt-get install -yq curl && \
  apt-get install -yq gnupg-agent && \
  apt-get install -yq software-properties-common && \
  curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
  apt-get update && \
  apt-get install -yq docker-ce=5:20.10.3~3-0~debian-buster && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir -p /opt/jenkins

WORKDIR /opt/jenkins

ADD http://mirrors.jenkins-ci.org/war-stable/2.263.4/jenkins.war /opt/jenkins/

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
