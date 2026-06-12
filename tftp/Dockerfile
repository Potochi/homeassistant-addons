FROM ghcr.io/home-assistant/base:3.23

ARG BUILD_VERSION="1.0.0"

RUN apk add --no-cache tftp-hpa

COPY run.sh /
RUN chmod a+x /run.sh

LABEL \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="app" \
    io.hass.arch="aarch64|amd64"

CMD [ "/run.sh" ]
