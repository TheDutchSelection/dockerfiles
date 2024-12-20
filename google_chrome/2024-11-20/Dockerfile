# NAME: Google Chrome 2024-11-20 (this is the date the image was made with the latest stable Chrome)
#
# DESCRIPTION: Image with Google Chrome for testing apps.
#
# REQUIRED ENVS:
#
# OPTIONAL ENVS:
#
# USAGE EXAMPLE:  docker run -d --shm-size=2g --rm -p 9223:9223 thedutchselection/google_chrome:2024-11-20

FROM thedutchselection/debian:12.8
LABEL org.opencontainers.image.authors="g.meijer@thedutchselection.com"

RUN apt-get update && apt-get install -y \
    curl \
    dbus \
    fonts-liberation \
    gnupg \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxrandr2 \
    libxi6 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libgbm1 \
    libasound2 \
    libpangocairo-1.0-0 \
    libgtk-3-0 \
    libvulkan1 \
    net-tools \
    socat \
    xdg-utils \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

ADD https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb /tmp

RUN dpkg -i google-chrome-stable_current_amd64.deb || apt-get -f install -y && \
    rm google-chrome-stable_current_amd64.deb

# Run Chrome in headless mode with remote debugging enabled
CMD ["/bin/sh", "-c", \
    "google-chrome-stable \
        --headless \
        --no-sandbox \
        --disable-gpu \
        --disable-dev-shm-usage \
        --disable-extensions \
        --disable-background-networking \
        --disable-software-rasterizer \
        --disable-sync \
        --remote-debugging-port=9222 & \
    sleep 5 && \
    socat TCP-LISTEN:9223,reuseaddr,fork TCP:127.0.0.1:9222"]
