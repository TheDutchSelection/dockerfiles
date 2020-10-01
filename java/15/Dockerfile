# NAME: Java 9
#
# DESCRIPTION: Base for other images using Java.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE: docker run thedutchselection/java

FROM thedutchselection/debian:10.4
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get update && \
  apt-get install -yq software-properties-common && \
  apt-get install -yq libasound2 && \
  apt-get install -yq libasound2-data && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget --no-cookies --no-check-certificate --header "Cookie: oraclelicense=accept-securebackup-cookie" https://download.oracle.com/otn-pub/java/jdk/15+36/779bf45e88a44cbd9ea6621d33e33db1/jdk-15_linux-x64_bin.deb

RUN dpkg -i jdk-15_linux-x64_bin.deb

RUN \
  update-alternatives --install /usr/bin/java java /usr/lib/jvm/jdk-15/bin/java 2 && \
  update-alternatives --install /usr/bin/jar jar /usr/lib/jvm/jdk-15/bin/jar 2 && \
  update-alternatives --install /usr/bin/javac javac /usr/lib/jvm/jdk-15/bin/javac 2 && \
  update-alternatives --set jar /usr/lib/jvm/jdk-15/bin/jar && \
  update-alternatives --set javac /usr/lib/jvm/jdk-15/bin/javac