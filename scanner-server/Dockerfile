ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base:9.3.0
FROM ${BUILD_FROM}

ARG BUILD_ARCH=aarch64
ARG BUILD_VERSION="1.0.0"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Epson Scan 2 6.7.80.0.
#
# The half of this driver that actually knows the Perfection V39 II -- the
# libcnx-esci-es0282.so connection plugin and the esfw0282.bin firmware blob
# that has to be pushed into the scanner before it answers -- is closed
# source. Epson only ever published it for x86_64, i686 and armv7l, and since
# there is no source there will never be an aarch64 build.
#
# So on 64-bit ARM the entire scanning stack is armhf, AirSane included, and
# runs under the kernel's AArch32 compatibility layer. It is all one process
# and one word size on purpose: SANE's network protocol does NOT interoperate
# between a 64-bit client and a 32-bit server. Device enumeration survives the
# mismatch, but sane_start desynchronises and both ends block on each other
# forever. Keeping everything armhf is what avoids that entirely.
#
# Every ELF in the bundle has 64K-aligned PT_LOAD segments, so this also loads
# on the 16K-page kernel Home Assistant OS ships for the Raspberry Pi 5.
ARG EPSON_URL_ARMV7L=https://download3.ebz.epson.net/dsc/f/03/00/17/08/16/ec9aaa15e4cc6ae6bb906ce999595644426ad2c8/epsonscan2-bundle-6.7.80.0.armv7l.deb.tar.gz
ARG EPSON_SHA256_ARMV7L=df565561ebce6682c219e7525391762a3b79a9e951ecb2bea8eba30078293789
ARG EPSON_URL_X86_64=https://download3.ebz.epson.net/dsc/f/03/00/17/08/12/9f3fec0ae80aa5c36f5170377ebcc38c93251e23/epsonscan2-bundle-6.7.80.0.x86_64.deb.tar.gz
ARG EPSON_SHA256_X86_64=e403d8338f4705b28244b8eef6833ae8a29a932f234b15b429798c78b5d70f01

# AirSane v0.4.12
ARG AIRSANE_COMMIT=129cc3bf7258251a0a694dee7741285b59d88f9f

# Runtime packages.
#
# On aarch64 everything that touches SANE is installed for armhf. Avahi and
# D-Bus stay native: AirSane only talks to them over a socket, which is IPC
# and carries no ABI, so a 32-bit client and a 64-bit daemon are fine.
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        avahi-daemon \
        dbus \
        ca-certificates \
        curl \
        netbase; \
    if [ "${BUILD_ARCH}" = "aarch64" ]; then \
        dpkg --add-architecture armhf; \
        apt-get update; \
        apt-get install -y --no-install-recommends \
            sane-utils:armhf \
            libsane1:armhf \
            libavahi-client3:armhf \
            libavahi-common3:armhf \
            libusb-1.0-0:armhf \
            libatomic1:armhf \
            libjpeg62-turbo:armhf \
            libpng16-16t64:armhf \
            libc6:armhf \
            libstdc++6:armhf \
            libgcc-s1:armhf \
            zlib1g:armhf \
            liblzma5:armhf \
            libjbig0:armhf; \
    else \
        apt-get install -y --no-install-recommends \
            sane-utils \
            libsane1 \
            libavahi-client3 \
            libavahi-common3 \
            libusb-1.0-0 \
            libatomic1 \
            libjpeg62-turbo \
            libpng16-16; \
    fi; \
    rm -rf /var/lib/apt/lists/*

# AirSane: the eSCL/AirScan server. Built from source because nobody packages
# it. On aarch64 it is cross-compiled to armhf so that it can dlopen Epson's
# 32-bit SANE backend directly -- see the note at the top of this file for why
# bridging the two word sizes over the network protocol is not an option.
RUN set -eux; \
    if [ "${BUILD_ARCH}" = "aarch64" ]; then \
        build_pkgs="crossbuild-essential-armhf cmake make \
            libsane-dev:armhf libjpeg-dev:armhf libpng-dev:armhf \
            libavahi-client-dev:armhf libusb-1.0-0-dev:armhf"; \
        cross_args="-DCMAKE_SYSTEM_NAME=Linux \
            -DCMAKE_SYSTEM_PROCESSOR=arm \
            -DCMAKE_C_COMPILER=arm-linux-gnueabihf-gcc \
            -DCMAKE_CXX_COMPILER=arm-linux-gnueabihf-g++ \
            -DCMAKE_LIBRARY_ARCHITECTURE=arm-linux-gnueabihf"; \
    else \
        build_pkgs="build-essential cmake make \
            libsane-dev libjpeg-dev libpng-dev \
            libavahi-client-dev libusb-1.0-0-dev"; \
        cross_args=""; \
    fi; \
    apt-get update; \
    apt-get install -y --no-install-recommends ${build_pkgs}; \
    curl -fsSL "https://github.com/SimulPiscator/AirSane/archive/${AIRSANE_COMMIT}.tar.gz" \
        -o /tmp/airsane.tar.gz; \
    mkdir -p /tmp/airsane; \
    tar -xzf /tmp/airsane.tar.gz -C /tmp/airsane --strip-components=1; \
    cmake -S /tmp/airsane -B /tmp/airsane/build \
        -DCMAKE_BUILD_TYPE=MinSizeRel \
        -DCMAKE_INSTALL_PREFIX=/usr \
        ${cross_args}; \
    cmake --build /tmp/airsane/build -j"$(nproc)"; \
    cmake --install /tmp/airsane/build; \
    apt-get purge -y --auto-remove ${build_pkgs}; \
    rm -rf /tmp/airsane /tmp/airsane.tar.gz /var/lib/apt/lists/*

# Epson Scan 2. Both debs declare no dependencies and unpack straight into the
# Debian multiarch layout the binaries were linked against, so a plain dpkg -i
# lands every file exactly where the hardcoded lookups expect it:
# libes2command.so execs <libdir>/epsonscan2/non-free-exec/es2intif, which in
# turn loads <libdir>/epsonscan2/libexec/libcnx-esci-*.so and reads firmware
# from /usr/share/epsonscan2. Epson also vendors its own libjpeg/libpng/libtiff
# next to them, so nothing else has to be pulled in.
RUN set -eux; \
    case "${BUILD_ARCH}" in \
        aarch64) url="${EPSON_URL_ARMV7L}"; sha="${EPSON_SHA256_ARMV7L}"; deb_arch=armhf ;; \
        amd64)   url="${EPSON_URL_X86_64}"; sha="${EPSON_SHA256_X86_64}"; deb_arch=amd64 ;; \
        *) echo "unsupported architecture: ${BUILD_ARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "${url}" -o /tmp/epsonscan2.tar.gz; \
    echo "${sha}  /tmp/epsonscan2.tar.gz" | sha256sum -c -; \
    mkdir -p /tmp/epsonscan2; \
    tar -xzf /tmp/epsonscan2.tar.gz -C /tmp/epsonscan2 --strip-components=1; \
    dpkg -i /tmp/epsonscan2/core/epsonscan2_*_"${deb_arch}".deb; \
    dpkg -i /tmp/epsonscan2/plugins/epsonscan2-non-free-plugin_*_"${deb_arch}".deb; \
    rm -rf /tmp/epsonscan2 /tmp/epsonscan2.tar.gz; \
    rm -f /usr/bin/epsonscan2 /usr/lib/*/epsonscan2/detectalert

# SANE backend list. Only the Epson backend is enabled: the stock backends
# would otherwise probe the same USB device, and several of them half-recognise
# Epson hardware they cannot actually drive. The dll.d drop-in the package
# ships says the same thing, but keeping the list in one file makes it obvious
# what is loaded.
RUN set -eux; \
    rm -f /etc/sane.d/dll.d/epsonscan2; \
    printf 'epsonscan2\n' > /etc/sane.d/dll.conf; \
    mkdir -p /etc/airsane

COPY rootfs /

RUN chmod a+x \
        /etc/s6-overlay/s6-rc.d/init-scanner/up \
        /etc/s6-overlay/s6-rc.d/dbus-daemon/run \
        /etc/s6-overlay/s6-rc.d/avahi-daemon/run \
        /etc/s6-overlay/s6-rc.d/airsane/run \
        /usr/local/bin/scanner-setup

EXPOSE 8090

LABEL \
    io.hass.name="Scanner Server" \
    io.hass.description="Share a USB scanner over the network with AirScan/eSCL" \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="addon" \
    io.hass.arch="aarch64|amd64"
