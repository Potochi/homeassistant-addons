## v2.1 (Potochi fork)

- Fix garbled `usb://` connection URI when adding a USB printer: generate and set an `en_US.UTF-8` locale so cupsd decodes the printer's IEEE-1284 device-ID correctly (previously ran in the C/ASCII locale)

## v2.0 (Potochi fork)

- Bump base image to `debian-base` 9.3.0 (Debian 12 bookworm → 13 trixie)
- `cups-pdf` renamed to `printer-driver-cups-pdf` upstream; updated package name (same code, "print to PDF" virtual printer unchanged)
- Side effect: `printer-driver-brlaser` bumps 6-3 → 6.2.7-1, adding HL-L2375DW / HL-L2390DW / MFC-L2750DW model entries

## v1.9 (Potochi fork)

- Point `repository.json` at this fork so HA registers it as a distinct repo instead of the upstream

## v1.8 (Potochi fork)

- Add `ServerAlias *` to `cupsd.conf` so the web UI is reachable by IP / hostname (CUPS otherwise rejects non-localhost Host headers with HTTP 400 "Bad Request")

## v1.7

- Fix the issue with "ulimit" size and permissions
  
## v1.5

- Update Debian Base to 7.6.2
- Add HP drivers (printer-driver-hpcups)
