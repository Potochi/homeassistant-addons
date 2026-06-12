ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm
FROM ${BUILD_FROM}

ARG BUILD_ARCH=amd64
ARG CALIBRE_VERSION=9.9.0

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    QT_QPA_PLATFORM=offscreen

# Runtime deps. Calibre bundles Qt6 but still dynamically loads these from the
# host (fontconfig, GL/EGL stubs, xcb shims, dbus, nss). xz-utils + ca-certs
# are needed just for the install step and could be purged, but they're tiny.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        xz-utils \
        libfontconfig1 \
        libegl1 \
        libgl1 \
        libxkbcommon0 \
        libxkbcommon-x11-0 \
        libxcb-cursor0 \
        libxcb-icccm4 \
        libxcb-image0 \
        libxcb-keysyms1 \
        libxcb-randr0 \
        libxcb-render-util0 \
        libxcb-shape0 \
        libxcb-sync1 \
        libxcb-xfixes0 \
        libxcb-xinerama0 \
        libxcb-xkb1 \
        libxcomposite1 \
        libxdamage1 \
        libxrandr2 \
        libxtst6 \
        libdbus-1-3 \
        libnss3 \
        libasound2 \
        libpulse0 \
        libgssapi-krb5-2 \
        libopengl0 \
        libxslt1.1 \
        libwoff1 \
        libsqlite3-0 \
        libsecret-1-0 \
        libdouble-conversion3 \
        libmd4c0 \
        libb2-1 \
        fonts-liberation \
    ; \
    rm -rf /var/lib/apt/lists/*

# Pull the official upstream Linux tarball and install in place.
# Upstream hosts versioned downloads at download.calibre-ebook.com/<version>/.
RUN set -eux; \
    case "${BUILD_ARCH}" in \
        amd64)   calibre_arch="x86_64" ;; \
        aarch64) calibre_arch="arm64"  ;; \
        *) echo "Unsupported arch: ${BUILD_ARCH}" >&2; exit 1 ;; \
    esac; \
    mkdir -p /opt/calibre; \
    curl -fsSL --retry 5 --retry-delay 3 \
        "https://download.calibre-ebook.com/${CALIBRE_VERSION}/calibre-${CALIBRE_VERSION}-${calibre_arch}.txz" \
        -o /tmp/calibre.txz; \
    tar -xJf /tmp/calibre.txz -C /opt/calibre; \
    rm /tmp/calibre.txz; \
    /opt/calibre/calibre_postinstall --bin-prefix /opt/calibre --share-prefix /opt/calibre/resources >/dev/null || true; \
    /opt/calibre/calibre --version

ENV PATH="/opt/calibre:${PATH}"

COPY run.sh /run.sh
RUN chmod a+x /run.sh

LABEL \
    io.hass.name="Calibre Server" \
    io.hass.description="Calibre headless content server" \
    io.hass.type="addon" \
    io.hass.arch="amd64|aarch64" \
    io.hass.version="1.0.0"

CMD [ "/run.sh" ]
