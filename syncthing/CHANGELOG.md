# Changelog

## 1.0.0

Initial release, built on Syncthing 2.0.10 from Alpine 3.23.

- Web UI through Home Assistant ingress, no separate login needed
- Pinnable device identity (`cert_pem` / `key_pem`), as a PEM block or a path,
  so the device ID is a constant a NixOS or nix-darwin flake can declare up
  front
- Declarative `peers` and `folders`, applied over the Syncthing REST API and
  merged into the running configuration, with optional `override_devices` /
  `override_folders` pruning
- `introducer` and `auto_accept_folders` support, with `folder_root` deciding
  where auto-accepted folders are created
- Maps `/share`, `/media`, `/homeassistant`, `/config` and `/backup`
- Device ID written to the log and to `/config/device-id.txt`
- `nix/gen-identity.sh` to generate an identity off-line and
  `nix/homeassistant-peer.nix`, a home-manager module for the other side
