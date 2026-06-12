#!/usr/bin/with-contenv bashio
# ==============================================================================
# Home Assistant add-on: Calibre Server
# Starts /opt/calibre/calibre-server against the configured library.
# ==============================================================================
set -e

LIBRARY=$(bashio::config 'library')
PORT=$(bashio::config 'port')
USERNAME=$(bashio::config 'username')
PASSWORD=$(bashio::config 'password')
ENABLE_LOCAL_WRITE=$(bashio::config 'enable_local_write')
LOG_LEVEL=$(bashio::config 'log_level')
EXTRA_ARGS=$(bashio::config 'extra_args')

USERDB=/data/users.sqlite

mkdir -p "${LIBRARY}"

# First run: prime the library so calibre-server has a metadata.db.
# `calibredb list` on a fresh path silently creates the schema.
if [ ! -f "${LIBRARY}/metadata.db" ]; then
    bashio::log.info "Initialising new Calibre library at ${LIBRARY}"
    /opt/calibre/calibredb list --library-path "${LIBRARY}" --fields=id >/dev/null
fi

# Bind dual-stack: `::` accepts both IPv4 (as v4-mapped) and IPv6 on Linux
# kernels with the default `net.ipv6.bindv6only=0`, which is what HA OS and
# every mainstream distro ship. Using 0.0.0.0 here would silently lose IPv6.
# --log /dev/stdout puts the startup banner in the HA log tab.
ARGS=(
    --listen-on "::"
    --port "${PORT}"
    --log /dev/stdout
    --access-log /dev/stdout
)

if bashio::var.true "${ENABLE_LOCAL_WRITE}"; then
    ARGS+=(--enable-local-write)
fi

# Auth: idempotently sync the configured user into /data/users.sqlite.
# add(8) creates the DB if missing; chpass(8) updates an existing user.
if bashio::var.has_value "${USERNAME}" && bashio::var.has_value "${PASSWORD}"; then
    if /opt/calibre/calibre-server --userdb "${USERDB}" --manage-users -- list 2>/dev/null \
        | grep -qx "${USERNAME}"; then
        bashio::log.info "Updating password for Calibre user '${USERNAME}'"
        /opt/calibre/calibre-server --userdb "${USERDB}" --manage-users -- \
            chpass "${USERNAME}" "${PASSWORD}" >/dev/null
    else
        bashio::log.info "Creating Calibre user '${USERNAME}'"
        /opt/calibre/calibre-server --userdb "${USERDB}" --manage-users -- \
            add "${USERNAME}" "${PASSWORD}" >/dev/null
    fi
    # --auth-mode basic so OPDS clients (KOReader, Moon+ Reader, FBReader,
    # Calibre Companion) work. Default `auto` advertises Digest first, which
    # those clients don't implement; they then receive a 400/401 they can't
    # recover from. Basic is fine over HTTP on a LAN; if you expose the
    # server publicly, front it with TLS.
    ARGS+=(--enable-auth --auth-mode basic --userdb "${USERDB}")
else
    bashio::log.warning "No username/password configured; server is open to anyone with network access."
fi

bashio::log.info "Starting calibre-server on port ${PORT} for library ${LIBRARY}"
# shellcheck disable=SC2086
exec /opt/calibre/calibre-server "${ARGS[@]}" ${EXTRA_ARGS} "${LIBRARY}"
