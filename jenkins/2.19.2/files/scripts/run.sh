#!/bin/bash
set -e

# remove any existing docker pid
rm -f /var/run/docker.pid

echo "set JENKINS_HOME to $DATA_DIRECTORY"
export JENKINS_HOME="$DATA_DIRECTORY"

host_docker_uid=$(stat -c %u /var/run/docker.sock)
host_docker_gid=$(stat -c %g /var/run/docker.sock)
echo "fixing docker user and group ids to $host_docker_uid : $host_docker_gid..."
usermod -u "$host_docker_uid" docker
groupmod -g "$host_docker_gid" docker


echo "starting jenkins..."
su jenkins -c "java -jar /opt/jenkins/jenkins.war --httpPort=8080" &
wait
