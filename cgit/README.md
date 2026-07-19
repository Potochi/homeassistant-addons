# CGit Server

Home Assistant add-on that serves your git repositories two ways:

- **Browse** them in your browser with [cgit](https://git.zx2c4.com/cgit/about/)
  (web UI + read-only HTTP clone).
- **Push** to them over SSH using a shared set of public keys — one key list for
  every repository, no per-repo access control.

Repositories live in a folder inside `/share`, so you can also reach them over
NFS or Samba. New repositories are created automatically on first push.

See [DOCS.md](DOCS.md) for configuration.
