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

# Same deps + OpenJDK 17; keep it lean and reproducible
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    openjdk-17-jdk-headless \
    libasound2 libasound2-data \
    libc6-i386 libc6-x32 \
    libxi6 libxrender1 libxtst6 \
    ca-certificates; \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Keep your old path stable for scripts expecting /usr/lib/jvm/jdk-17
RUN ln -sfn /usr/lib/jvm/java-17-openjdk-amd64 /usr/lib/jvm/jdk-17

# Optional but handy: define JAVA_HOME & verify at build
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"
RUN java -version