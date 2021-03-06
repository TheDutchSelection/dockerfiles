#!/bin/bash
set -e

# remove any existing docker pid
rm -f /var/run/docker.pid

if [[ -f "$SSH_KEY" && -f  "$SSH_PUB_KEY" ]]; then
  known_host_file=$(dirname "${SSH_KEY}")"/known_hosts"
  touch "$known_host_file"
  chown jenkins:jenkins "$SSH_KEY"
  chown jenkins:jenkins "$SSH_PUB_KEY"
  chown jenkins:jenkins "$known_host_file"
  chmod 400 "$SSH_KEY"
  chmod 400 "$SSH_PUB_KEY"
fi

echo "set JENKINS_HOME to $DATA_DIRECTORY"
export JENKINS_HOME="$DATA_DIRECTORY"

host_docker_gid=$(stat -c %g /var/run/docker.sock)
echo "fixing docker group id to $host_docker_gid..."
groupmod -g "$host_docker_gid" docker


echo "starting jenkins..."
su jenkins -c "java -jar /opt/jenkins/jenkins.war --httpPort=8080" &
wait
