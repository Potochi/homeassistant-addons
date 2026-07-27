# Changelog

## 1.1.0

- Pushes now require **signed commits** by default (`require_signed_commits`).
  A server-side `pre-receive` hook verifies every commit that is new to the
  repository with `git verify-commit`; unsigned or untrusted commits are
  rejected with a clear message. Existing history is never re-judged.
- Trusted signing keys are configured with `allowed_signers` (SSH signatures,
  `allowed-signers` format) and `gpg_public_keys` (armored OpenPGP public key
  blocks). The trusted set is rebuilt from the options on every start.
- **Breaking:** with the new default, pushes are rejected until you add your
  signing key to `allowed_signers`/`gpg_public_keys` (and sign your commits) or
  set `require_signed_commits: false`.

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
