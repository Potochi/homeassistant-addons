# Calibre Server — Documentation

## Quick start

1. Install the add-on.
2. Set `library` to a directory under `/share`, `/media`, or one of the other
   mapped Home Assistant directories. Default: `/share/calibre`.
3. (Recommended) Set `username` and `password` to enable authentication.
4. Start the add-on. Open the web UI from the add-on page or browse to
   `http://<home-assistant-host>:8080/`.

On first start an empty library is created at the configured path. Add books
through the web UI (`enable_local_write` must remain `true`) or by dropping
files into the library directory and using **Run library check** from the UI.

## Options

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `library` | path | `/share/calibre` | Path inside the container that the server should serve. Must live under one of the mapped host directories (`/share`, `/media`). |
| `port` | int | `8080` | TCP port calibre binds on the host (host network mode — no docker port mapping). |
| `username` | str | `""` | When set together with `password`, enables HTTP auth. |
| `password` | str | `""` | Companion to `username`. |
| `enable_local_write` | bool | `true` | Allow authenticated users to add/edit books from the web UI. |
| `log_level` | enum | `info` | Reserved; Calibre's own server logs are emitted on stdout. |
| `extra_args` | str | `""` | Raw extra arguments appended to the `calibre-server` command line. |

## Networking

The add-on runs in **host network mode** so calibre's Bonjour/mDNS service
advertisement reaches your LAN. Concretely:

- `port` (default `8080`) is bound directly on the Home Assistant host's
  network interfaces — there is no docker port mapping in between.
- Pick a value that is free on the host (HA Core itself is on 8123, so 8080
  is normally fine).
- The container can see and use the host's network. This is required for
  device discovery; if you'd rather keep the container isolated, accept
  that Kindles / KOReader / Calibre Companion will not auto-find the
  server and you'll have to enter the URL manually.

For remote access front the port with a reverse proxy (NGINX Proxy Manager,
Caddy, Traefik) and use the add-on's own auth or your proxy's auth.

## User management

Setting `username` / `password` in the add-on options provisions exactly that
user in `/data/users.sqlite`. Changing the password in options on a subsequent
start updates the existing user (`chpass`); changing the username creates a
new one alongside the old. To remove or add additional users, exec into the
container and use:

```sh
calibre-server --userdb /data/users.sqlite --manage-users -- list
calibre-server --userdb /data/users.sqlite --manage-users -- remove <user>
calibre-server --userdb /data/users.sqlite --manage-users -- add <user> <pw>
```

## Library on the host

`metadata.db` and the per-book folders are written to the path you pick in
`library`. Back this up like any other file. The add-on never touches the
library outside of what `calibre-server` itself does.

## Updating Calibre

Calibre is pinned by `CALIBRE_VERSION` in `build.yaml`. To take a newer
upstream release, bump that value and the add-on `version` in `config.yaml`,
then rebuild from the add-on page.
