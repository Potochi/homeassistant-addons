# Syncthing

Makes Home Assistant a Syncthing peer. Its device identity can be pinned from
the add-on options, so your NixOS or nix-darwin flake can declare Home
Assistant as a peer before the add-on has ever been started, and adding a
folder on your laptop needs no change on the Home Assistant side.

## Installation

1. Install the add-on and open **Configuration**.
2. Generate an identity (see below) or start it as-is and read the device ID
   from the log.
3. Start it. The web UI is in the sidebar; it is already behind Home
   Assistant's login, so no Syncthing password is needed.

## Pinning the device identity

A Syncthing device ID is the fingerprint of its certificate. Let the add-on
generate one and the ID is whatever it happens to be - and it changes if
`/data` is ever lost. Generate it up front instead and the ID becomes a
constant your flake can hard-code:

```console
$ nix shell nixpkgs#syncthing -c ./nix/gen-identity.sh ~/secrets/ha-syncthing

Device ID: R3FQJ27-YQ4IGRW-GEIIJ66-S5ACUTW-GINJH47-5FYDDJJ-J2YIERC-CGV37QS
...
cert_pem: |
  -----BEGIN CERTIFICATE-----
  ...
key_pem: |
  -----BEGIN EC PRIVATE KEY-----
  ...
```

Paste the two blocks into the add-on configuration (**Edit in YAML**), or drop
the files somewhere readable and give the paths instead:

```yaml
cert_pem: /ssl/syncthing/cert.pem
key_pem: /ssl/syncthing/key.pem
```

Device IDs are public and safe to commit. `key.pem` is not: anyone holding it
can impersonate this instance.

The add-on writes its device ID to the log on every start and to
`/config/device-id.txt`, reachable from Samba or SSH as
`addon_configs/*_syncthing/device-id.txt`.

## Letting NixOS drive the syncing

Syncthing is symmetric: each side has to know the other's device ID. Once both
identities are pinned, the two config files are just two constants, and you can
make your laptop the only place folders are declared.

**On the laptop** (`nix/homeassistant-peer.nix`, a home-manager module -
nix-darwin has no `services.syncthing`):

```nix
services.syncthing = {
  enable = true;
  cert = config.sops.secrets."syncthing/cert.pem".path;
  key = config.sops.secrets."syncthing/key.pem".path;
  overrideDevices = true;
  overrideFolders = true;
  settings = {
    devices.homeassistant = {
      id = "R3FQJ27-...";                          # from gen-identity.sh
      addresses = [ "tcp://homeassistant.local:22000" ];
    };
    folders.notes = {
      path = "${config.home.homeDirectory}/Notes";
      devices = [ "homeassistant" ];
    };
  };
};
```

**In the add-on**, name that laptop once and let it introduce the rest:

```yaml
device_name: homeassistant
folder_root: /share/syncthing
peers:
  - id: URMOCL4-...                                # the laptop's device ID
    name: mac
    introducer: true
    auto_accept_folders: true
folders: []
```

From then on, a folder added to `settings.folders` in your flake and shared
with `homeassistant` shows up on Home Assistant by itself, created at
`<folder_root>/<label>`. Nothing to click.

`introducer: true` additionally means devices your laptop syncs with are
offered to Home Assistant, so a new machine only has to be added in the flake.

Both of those hand the laptop the ability to create folders under
`folder_root`. If you would rather keep Home Assistant in charge, leave both
off and declare the folders in the `folders` option instead:

```yaml
folders:
  - id: ha-config
    label: HA config
    path: /homeassistant
    type: sendonly
    devices: [mac]
    versioning: staggered
```

## Where folders can live

Only these paths survive an add-on update, and only they are visible to
Syncthing:

| Path | Home Assistant directory |
|------|--------------------------|
| `/share` | Shared storage (also on Samba/NFS) |
| `/media` | Media |
| `/homeassistant` | Home Assistant's own configuration |
| `/config` | This add-on's configuration directory |
| `/backup` | Backups |

Anything else is inside the container and disappears on the next restart; the
add-on logs a warning if a declared folder points outside this list.

Syncing `/homeassistant` is useful but sharp: a `receiveonly` folder on the
laptop can never push a broken `configuration.yaml` back. Prefer that over
`sendreceive` unless you mean it.

## Networking

The add-on runs on Home Assistant's internal bridge network, so LAN broadcast
discovery does not reach it - announcements would carry an unroutable
`172.30.x.x` address. That does not matter for the usual setup, because the
laptop roams and Home Assistant does not: give the peer a fixed address for
Home Assistant (`tcp://homeassistant.local:22000`) and let it connect
inwards. Global discovery and relays stay on as a fallback.

Ports:

| Port | Purpose |
|------|---------|
| 22000/tcp | Sync protocol |
| 22000/udp | Sync protocol over QUIC |
| 21027/udp | Local discovery announcements |

Forward 22000/tcp on your router if you want direct connections from outside
the house; otherwise Syncthing falls back to a relay, which is slower but still
end-to-end encrypted.

## Options

| Option | Default | What it does |
|--------|---------|--------------|
| `device_name` | `homeassistant` | Name shown on your other machines. |
| `folder_root` | `/share/syncthing` | Where auto-accepted folders are created, as `<folder_root>/<label>`. |
| `cert_pem` / `key_pem` | empty | Pinned identity, as a PEM block or a path to one. Both or neither. |
| `peers` | `[]` | Machines to sync with; `id` is required. |
| `folders` | `[]` | Folders managed from here rather than from a peer. |
| `override_devices` | `false` | Delete peers that are not in `peers`. |
| `override_folders` | `false` | Delete folders that are not in `folders`. |
| `gui_user` / `gui_password` | empty | Extra login on the web UI. Only needed if you expose port 8384. |
| `local_discovery` | `true` | Announce on the LAN (see above). |
| `global_discovery` | `true` | Use the public discovery servers. |
| `relays_enabled` | `true` | Fall back to public relays. |
| `nat_traversal` | `true` | Ask the router for a port mapping. |

`peers[]` takes `id`, `name`, `addresses`, `introducer`,
`auto_accept_folders`, `compression`, `untrusted` and `paused`.

`folders[]` takes `id`, `label`, `path`, `type`, `devices` (peer names or
device IDs), `rescan_interval`, `fs_watcher`, `ignore_perms`, `versioning`
(`none`, `trashcan`, `simple`, `staggered`) and `versioning_param` (days for
`trashcan` and `staggered`, number of versions for `simple`).

### How the options are applied

Devices and folders are merged into the running configuration, not replaced:
an existing entry is used as the base and only the keys an option covers are
overwritten. Anything you change in the web UI on top of that survives a
restart, and removing an entry from the options does not delete it unless the
matching `override_*` is on.

Two consequences worth knowing:

- `auto_accept_folders` and `override_folders` fight each other. The prune
  removes the auto-accepted folder, the peer offers it again, and it comes
  straight back. Pick one.
- GUI credentials are only written when both `gui_user` and `gui_password` are
  set. Clearing the options does not remove the login - do that in the
  Syncthing UI, otherwise a password you set there would be wiped on restart.

## Backups

`/data` holds the identity, `config.xml` and the index database, and all of it
goes into Home Assistant backups. The index grows with the number of synced
files, so a large sync set makes every backup noticeably bigger. The synced
files themselves live in `/share`, `/media` and friends and follow whatever
those are set to.

Restoring a backup restores the identity as well, so the device ID comes back
unchanged - and with a pinned `cert_pem`/`key_pem` it survives even a full
reinstall.

## Troubleshooting

**The peer never connects.** Check that both sides list each other's device ID;
Syncthing needs both. Then check the address: on the bridge network the add-on
cannot be found by LAN discovery, so the peer needs
`tcp://<home-assistant>:22000` spelled out.

**"folder marker missing".** The folder path was removed, or points somewhere
outside the mapped directories. Recreate the directory or fix the path.

**The add-on stops right after starting.** Configuration errors are fatal on
purpose. The log line before the s6 messages says which option is wrong -
usually one half of an identity pair, or a folder path that cannot be created.

**A folder shows out of sync forever.** Look at the file's owner: Syncthing
runs as root here and can write anywhere, but a peer syncing ownership onto a
Samba share can produce files it then cannot modify. Turn `ignore_perms` on
for that folder.
