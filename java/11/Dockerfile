# NAME: Java 11
#
# DESCRIPTION: Base for other images using Java.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE: docker run thedutchselection/java

FROM thedutchselection/debian:10.4
LABEL org.opencontainers.image.authors="g.meijer@thedutchselection.com"

RUN \
  apt-get update && \
  apt-get install -yq software-properties-common && \
  apt-get install -yq libasound2 && \
  apt-get install -yq libasound2-data && \
  apt-get install -yq openjdk-11-jdk && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*