FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic as base
ARG VERSION
WORKDIR /tmp
COPY ./checksums.txt .
RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    wget=1.19.4-1ubuntu2.2 && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/ \
    /var/tmp/*

FROM base as base_amd64
ARG VERSION
ARG FILENAME="writefreely_${VERSION}_linux_amd64.tar.gz"
WORKDIR /tmp
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN \
  echo "**** download installer ****" && \
  wget -q "https://github.com/writefreely/writefreely/releases/download/v${VERSION}/${FILENAME}" && \
  sha256sum "./${FILENAME}" | sha256sum --ignore-missing -c ./checksums.txt || if [ "$?" -eq "141" ]; then true; else exit $?; fi && \
  tar -xvf "${FILENAME}" -C /app --strip-components 1 && \
  chmod +x /app/writefreely

FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic as build_amd64
COPY --from=base_amd64 /app /app

#########################

FROM base as base_arm64
ARG VERSION
ARG FILENAME="writefreely_${VERSION}_linux_arm64.tar.gz"
WORKDIR /tmp
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN \
  echo "**** download installer ****" && \
  wget -q "https://github.com/writefreely/writefreely/releases/download/v${VERSION}/${FILENAME}" && \
  sha256sum "./${FILENAME}" | sha256sum --ignore-missing -c ./checksums.txt || if [ "$?" -eq "141" ]; then true; else exit $?; fi && \
  tar -xvf "${FILENAME}" -C /app --strip-components 1 && \
  chmod +x /app/writefreely

FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic as build_arm64
COPY --from=base_arm64 /app /app

#########################

FROM base as base_arm
ARG VERSION
ARG FILENAME="writefreely_${VERSION}_linux_arm7.tar.gz"
WORKDIR /tmp
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN \
  echo "**** download installer ****" && \
  wget -q "https://github.com/writefreely/writefreely/releases/download/v${VERSION}/${FILENAME}" && \
  sha256sum "./${FILENAME}" | sha256sum --ignore-missing -c ./checksums.txt || if [ "$?" -eq "141" ]; then true; else exit $?; fi && \
  tar -xvf "${FILENAME}" -C /app --strip-components 1 && \
  chmod +x /app/writefreely

FROM ghcr.io/linuxserver/baseimage-ubuntu:bionic as build_arm
COPY --from=base_arm /app /app

########################

# hadolint ignore=DL3006
FROM build_${TARGETARCH}
ARG BUILD_DATE
ARG VERSION
# hadolint ignore=DL3048
LABEL build_version="Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="nicholaswilde"


# copy local files
COPY root/ /

WORKDIR /app
RUN \
  echo "**** install packages ****" && \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    netcat=1.10-41.1 && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/ \
    /var/tmp/* && \
  mkdir /data

# ports and volumes
EXPOSE 8080
VOLUME \
  /config \
  /data \
  /app
