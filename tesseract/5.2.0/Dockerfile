# NAME: Tesseract 5.2.0
#
# DESCRIPTION:
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
# PASSWORD (ie. "abcdabcd1234")
# MAX_MEMORY_IN_BYTES (ie. "1073741824", best is to keep 10% of memory for overhead)
#
# OTHER:

FROM thedutchselection/debian:11.5
MAINTAINER Gerard Meijer <g.meijer@thedutchselection.com>

RUN \
  apt-get -yq update && \
  apt-get -yq install automake && \
  apt-get -yq install ca-certificates && \
  apt-get -yq install g++ && \
  apt-get -yq install libtool && \
  apt-get -yq install libleptonica-dev && \
  apt-get -yq install make && \
  apt-get -yq install pkg-config && \
  apt-get -yq install libpango1.0-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

WORKDIR /opt

RUN git clone https://github.com/tesseract-ocr/tesseract.git

RUN \
  cd tesseract && \
  git checkout tags/5.2.0 && \
  chmod +x autogen.sh && \
  ./autogen.sh && \
  mkdir -p bin/release && \
  cd bin/release && \
  ../../configure --disable-openmp --disable-shared 'CXXFLAGS=-g -O2 -fno-math-errno -Wall -Wextra -Wpedantic' && \
  make training && \
  ln -s /opt/tesseract/bin/release/tesseract /usr/local/bin/tesseract && \
  ln -s /opt/tesseract/bin/release/tesseract /usr/bin/tesseract

# Add the required language training data
# Find them here https://github.com/tesseract-ocr/tessdata_best
ADD --chmod=666 https://github.com/tesseract-ocr/tessdata_best/raw/main/osd.traineddata /usr/local/share/tessdata/
ADD --chmod=666 https://github.com/tesseract-ocr/tessdata_best/raw/main/eng.traineddata /usr/local/share/tessdata/

WORKDIR /tmp
