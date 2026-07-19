# Changelog

## 1.0.0

- Initial release.
- Browse repositories with cgit 1.2.3 served by lighttpd on Alpine 3.23.
- Repositories scanned from `/share/<repos_dir>` (default `/share/git`), so they
  are also reachable over NFS/Samba.
- Read-only clone/fetch over HTTP via `git-http-backend`; push is refused over
  HTTP.
- Push/fetch over SSH restricted to the keys in `push_keys` (one shared key set
  for every repo). Interactive logins and path traversal are refused.
- Optional auto-creation of bare repositories on first push (`auto_init`), with
  automatic `HEAD` repair so HTTP clones work immediately.
- Advertises SSH and HTTP clone URLs on each repo page (`clone_url_ssh`,
  `enable_http_clone`).
- Configurable `git` service user UID/GID for NFS/Samba ownership, optional
  ownership fix-up (`fix_permissions`), and raw `cgitrc` passthrough
  (`extra_cgitrc`).
- SSH host keys persisted in `/data/ssh` across restarts and updates.
