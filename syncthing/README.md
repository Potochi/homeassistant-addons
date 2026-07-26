# Syncthing

Continuous file synchronisation between Home Assistant and your other
machines.

The device identity can be pinned from the add-on options, so a NixOS or
nix-darwin flake can declare this instance as a peer before it has ever been
started. Combined with `introducer` and `auto_accept_folders`, a folder added
to your flake appears on Home Assistant on its own - no Home Assistant side
change to add a folder.

- Web UI in the Home Assistant sidebar, behind the usual login
- Syncs `/share`, `/media`, `/homeassistant`, `/config` and `/backup`
- Declarative peers and folders, merged into anything you set in the web UI
- `nix/` holds an identity generator and a ready-made home-manager module

See [DOCS.md](DOCS.md) for the setup, the NixOS workflow and every option.
