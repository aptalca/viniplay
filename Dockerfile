FROM ghcr.io/linuxserver/baseimage-alpine:3.22

LABEL maintainer="aptalca"
LABEL org.opencontainers.image.source=https://github.com/aptalca/viniplay

ARG APP_VERSION

ENV HOME="/config"

RUN \
  echo "**** install build deps ****" && \
  apk add --no-cache --virtual=build-dependencies \
    build-base \
    py3-setuptools \
    python3 && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    ffmpeg \
    npm && \
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
  ln -s /config /data && \
  mkdir -p /dvr && \
  echo "**** cleanup ****" && \
  apk del --purge \
    build-dependencies && \
  rm -rf \
    /tmp/* \
    "${HOME}"/.npm

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 80 443
