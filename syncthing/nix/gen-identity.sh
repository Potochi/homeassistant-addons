#!/usr/bin/env bash
# ==============================================================================
# Generates a Syncthing identity for the Home Assistant add-on, off-line.
#
# Run this once on your laptop:
#
#     nix shell nixpkgs#syncthing -c ./gen-identity.sh ~/secrets/ha-syncthing
#
# It prints the device ID (a constant your flake can hard-code from now on) and
# the YAML to paste into the add-on configuration. Keep key.pem secret; anyone
# holding it can impersonate your Home Assistant instance.
# ==============================================================================
set -euo pipefail

out="${1:-./ha-syncthing-identity}"

if ! command -v syncthing > /dev/null 2>&1; then
    echo "syncthing not found on PATH. Try: nix shell nixpkgs#syncthing -c $0 $*" >&2
    exit 1
fi

if [[ -e "${out}/key.pem" ]]; then
    echo "${out}/key.pem already exists; refusing to overwrite an identity." >&2
    exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "${tmp}"' EXIT

syncthing generate --home "${tmp}" --no-port-probing > /dev/null 2>&1
device_id="$(syncthing device-id --home "${tmp}")"

mkdir -p "${out}"
chmod 700 "${out}"
cp "${tmp}/cert.pem" "${tmp}/key.pem" "${out}/"
chmod 600 "${out}/key.pem"
chmod 644 "${out}/cert.pem"

cat <<EOF

Device ID: ${device_id}

Written to ${out}/cert.pem and ${out}/key.pem.

--- Home Assistant: Syncthing add-on -> Configuration -> Edit in YAML ----------

cert_pem: |
$(sed 's/^/  /' "${out}/cert.pem")
key_pem: |
$(sed 's/^/  /' "${out}/key.pem")

--- home-manager --------------------------------------------------------------

  haDeviceId = "${device_id}";

EOF
