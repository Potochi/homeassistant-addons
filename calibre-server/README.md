# Calibre Server (Home Assistant add-on)

Runs the official [Calibre content server](https://manual.calibre-ebook.com/server.html)
v9.9.0 in a container, serving an e-book library over HTTP (web UI + OPDS).

## Highlights

- Latest upstream Calibre (9.9.0) installed from the official Linux tarball.
- Multi-arch: `amd64`, `aarch64` (Raspberry Pi 4/5, Intel/AMD x86_64).
- Library lives on the host via the `/share` or `/media` mounts — survives
  add-on reinstalls.
- Optional auth: provide `username` / `password` in the add-on config and the
  server is restarted in authenticated mode.
- Per-user write permission is enabled by default (`enable_local_write: true`)
  so you can upload books and edit metadata from the web UI.

See [DOCS.md](./DOCS.md) for option reference.
