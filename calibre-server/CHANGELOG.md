# Changelog

## 1.1.2 — 2026-06-06

- Force `--auth-mode basic` when auth is enabled. Calibre's default `auto`
  mode advertises HTTP Digest first, which OPDS clients (KOReader, Moon+
  Reader, FBReader, Calibre Companion) do not implement — they send Basic
  credentials, calibre's Digest handler rejects them with 400, and the
  catalog fails to load. Basic auth on the LAN is fine; front with TLS if
  you expose the server beyond it.

## 1.1.1 — 2026-06-06

- Add `icon.png` (512×512, rounded square, open-book with gold ribbon on a
  warm cocoa gradient) and `logo.png` (500×150 banner) so the add-on store
  card and sidebar entry no longer fall back to the placeholder image.

## 1.1.0 — 2026-06-06

- Switch to `host_network: true`. Calibre's Bonjour announcements were being
  emitted with the docker-internal IP (172.x) and the mDNS packets never
  left the container's network namespace, so Kindle/KOReader/etc. couldn't
  auto-discover the server. Sharing the host network namespace fixes both.
- Removed the now-unused `ports` mapping; the `port` option (default 8080)
  is what calibre binds directly on the host.

## 1.0.3 — 2026-06-06

- Listen on `::` (dual-stack) instead of `0.0.0.0`. The previous IPv4-only
  bind made the server unreachable over IPv6, even when the host port was
  published on both address families.

## 1.0.2 — 2026-06-06

- Force `calibre-server --log /dev/stdout --access-log /dev/stdout` so the
  startup banner (which prints the bound address) and request log show up in
  the add-on's Log tab, making "why can't I reach it?" debuggable.

## 1.0.1 — 2026-06-06

- Set `init: false` in the add-on manifest. Without it, Docker's default init
  wrapper takes PID 1 and s6-overlay v3 (used by the HA Debian base) aborts
  with `s6-overlay-suexec: fatal: can only run as pid 1`.

## 1.0.0 — 2026-06-05

- Initial release.
- Calibre **9.9.0** (upstream Linux tarball) on Debian Bookworm base.
- amd64 and aarch64 builds.
- Optional HTTP auth via `username` / `password` add-on options.
- Library served from a host-mapped path (default `/share/calibre`).
