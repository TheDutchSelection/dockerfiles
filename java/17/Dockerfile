# NAME: Java 17
#
# DESCRIPTION: Base for other images using Java.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE: docker run thedutchselection/java

FROM thedutchselection/debian:12.8
LABEL org.opencontainers.image.authors="g.meijer@thedutchselection.com"

RUN \
  apt-get update && \
  apt-get install -yq software-properties-common && \
  apt-get install -yq libasound2 && \
  apt-get install -yq libasound2-data && \
  apt-get install -yq libc6-i386 && \
  apt-get install -yq libc6-x32 && \
  apt-get install -yq libxi6 && \
  apt-get install -yq libxrender1 && \
  apt-get install -yq libxtst6 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.deb

RUN dpkg -i jdk-17_linux-x64_bin.deb

RUN \
  update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk-17/bin/java 2 && \
  update-alternatives --install /usr/bin/jar jar /usr/lib/jvm/jdk-17/bin/jar 2 && \
  update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk-17/bin/javac 2 && \
  update-alternatives --set jar /usr/lib/jvm/jdk-17/bin/jar && \
  update-alternatives --set javac /usr/lib/jvm/jdk-17/bin/javac