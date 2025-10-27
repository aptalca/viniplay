FROM ghcr.io/linuxserver/baseimage-ubuntu:noble

LABEL maintainer="aptalca"
LABEL org.opencontainers.image.source=https://github.com/aptalca/viniplay

ARG APP_VERSION

ENV \
  HOME="/config" \
  DEBIAN_FRONTEND="noninteractive" \
  ATTACHED_DEVICES_PERMS="/dev/dri -type c"

RUN \
  echo "**** add jellyfin repo ****" && \
  curl -s https://repo.jellyfin.org/ubuntu/jellyfin_team.gpg.key | gpg --dearmor | tee /usr/share/keyrings/jellyfin.gpg >/dev/null && \
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/jellyfin.gpg] https://repo.jellyfin.org/ubuntu noble main' > /etc/apt/sources.list.d/jellyfin.list && \
  echo "**** install build packages ****" && \
  apt update && \
  apt-get install -y \
    build-essential \
    python3-setuptools && \
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
  echo "**** install runtime packages ****" && \
  apt-get install -y --no-install-recommends \
    jellyfin-ffmpeg7 \
    mesa-va-drivers \
    nodejs \
    vainfo && \
  echo "**** install npm ****" && \
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
  echo "**** install app ****" && \
  if [ -z "${APP_VERSION+x}" ]; then \
    APP_VERSION=$(curl -sfX GET "https://api.github.com/repos/ardoviniandrea/ViniPlay/releases/latest" \
      | jq -r '.tag_name'); \
  fi && \
  mkdir -p /app && \
  curl -o \
    /tmp/app.tar.gz -fL \
    "https://github.com/ardoviniandrea/ViniPlay/archive/${APP_VERSION}.tar.gz" && \
  tar xf \
    /tmp/app.tar.gz -C \
    /app --strip-components=1 && \
  cd /app && \
  npm install --only=production && \
  ln -s /usr/lib/jellyfin-ffmpeg/ffmpeg /usr/bin/ffmpeg && \
  ln -s /config /data && \
  mkdir -p /dvr && \
  echo "**** cleanup ****" && \
  apt-get -y purge \
    build-essential \
    python3-setuptools && \
  apt-get -y autoremove && \
  rm -rf \
    /var/lib/apt/lists/* \
    /var/tmp/* \
    /tmp/* \
    "${HOME}"/.npm

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
