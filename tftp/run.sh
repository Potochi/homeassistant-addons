#!/usr/bin/with-contenv bashio
# ==============================================================================
# TFTP Server for Home Assistant
# Serves /share/<directory> over TFTP (UDP port 69, host network).
# ==============================================================================

readonly CONFIG_PATH=/data/options.json

opt() { jq -r "${1}" "${CONFIG_PATH}"; }

directory="$(opt '.directory // empty')"
allow_uploads="$(opt '.allow_uploads == true')"
verbose="$(opt '.verbose != false')"
extra_args="$(opt '.extra_args // empty')"

# Normalize: strip leading/trailing slashes, refuse path escapes.
while [[ "${directory}" == /* ]]; do directory="${directory#/}"; done
while [[ "${directory}" == */ ]]; do directory="${directory%/}"; done

if [[ -z "${directory}" ]]; then
    bashio::exit.nok "Option 'directory' must not be empty"
fi
if [[ "${directory}" == *..* ]]; then
    bashio::exit.nok "Option 'directory' must not contain '..'"
fi

root="/share/${directory}"
mkdir -p "${root}"

args=(--foreground --secure --address 0.0.0.0:69 --user nobody)

if [[ "${allow_uploads}" == "true" ]]; then
    # tftpd drops privileges to 'nobody'; the folder must be writable by it
    # for uploads to work. umask 000 keeps uploaded files readable over NFS.
    chmod 0777 "${root}"
    args+=(--create --permissive --umask 000)
    bashio::log.info "Uploads are enabled (TFTP clients can create files)"
fi

if [[ "${verbose}" == "true" ]]; then
    args+=(--verbosity 3)
fi

if [[ -n "${extra_args}" ]]; then
    # shellcheck disable=SC2206
    args+=(${extra_args})
fi

bashio::log.info "Starting TFTP server on UDP port 69, serving ${root}"

# in.tftpd logs to syslog only: run busybox syslogd forwarding to this
# app's stdout so transfers show up in the Home Assistant log.
busybox syslogd -n -S -O /proc/self/fd/1 &

exec /usr/sbin/in.tftpd "${args[@]}" "${root}"
