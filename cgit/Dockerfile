ARG BUILD_FROM=ghcr.io/home-assistant/aarch64-base:3.23
FROM ${BUILD_FROM}

ARG BUILD_VERSION="1.0.0"

# cgit           - the CGI git viewer (cgit.cgi + assets in /usr/share/webapps/cgit)
# git            - core git + git-shell (the SSH push/fetch gatekeeper)
# git-daemon     - ships git-http-backend (smart HTTP clone/fetch)
# gpg            - verifies OpenPGP commit signatures (require_signed_commits)
# lighttpd       - serves cgit.cgi and git-http-backend over CGI
# openssh-server - sshd for git-over-ssh push/fetch
RUN apk add --no-cache \
        cgit \
        git \
        git-daemon \
        gpg \
        lighttpd \
        openssh-server \
        openssh-keygen

COPY rootfs /

RUN chmod a+x \
        /etc/s6-overlay/s6-rc.d/init-cgit/up \
        /usr/local/bin/cgit-setup \
        /usr/local/bin/git-shell-wrapper \
        /usr/local/bin/git-pre-receive-signed \
    && chmod a+x \
        /etc/s6-overlay/s6-rc.d/cgit-httpd/run \
        /etc/s6-overlay/s6-rc.d/git-sshd/run

LABEL \
    io.hass.name="CGit Server" \
    io.hass.description="cgit git viewer with SSH push for Home Assistant" \
    io.hass.version="${BUILD_VERSION}" \
    io.hass.type="app" \
    io.hass.arch="aarch64|amd64"
