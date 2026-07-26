ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:3.23
FROM ${BUILD_FROM}

ARG BUILD_VERSION="1.0.0"

# syncthing - the sync daemon itself (Alpine community, v2.x)
# curl, jq  - used by syncthing-apply to drive the REST API
RUN apk add --no-cache \
        syncthing \
        curl \
        jq

COPY rootfs /

RUN chmod a+x \
        /etc/s6-overlay/s6-rc.d/init-syncthing/up \
        /etc/s6-overlay/s6-rc.d/init-syncthing-apply/up \
        /etc/s6-overlay/s6-rc.d/syncthing/run \
        /usr/local/bin/syncthing-setup \
        /usr/local/bin/syncthing-apply

LABEL \
    io.hass.name="Syncthing" \
    io.hass.description="Syncthing peer for Home Assistant with a pinnable device identity" \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="app" \
    io.hass.arch="aarch64|amd64"
