# Changelog

## 1.0.1

- Fix clients finding the scanner but hanging when they open it, macOS Image
  Capture in particular. Avahi and AirSane both name things after
  `gethostname()`, which inside an add-on container is the slug
  `<hash>-scanner-server`. That name went into the SRV record of the published
  service and into the `adminurl`/`representation` TXT records, and nothing on
  the network can resolve it. Browsing still worked, because the instance name
  is only a label, so the scanner appeared and then hung on open while the
  client waited on a host that does not exist.
  Avahi is now pointed at the Home Assistant host's own name, and AirSane is
  started with `--announce-base-url=http://%H:8090` so its URLs match the SRV
  record. Avahi publishes no address records, so it never probes for that name
  and cannot lose the conflict against the host's own responder - which would
  have renamed it to `<name>-2` and broken it all over again.

## 1.0.0

- Initial release.
- Shares a USB scanner over **AirScan/eSCL** with AirSane 0.4.12, announced
  over mDNS, so it appears by itself in macOS Image Capture, on iOS, in
  Windows 10/11, in Mopria on Android and through `sane-airscan` on Linux.
- Web interface on port 8090 for clients that cannot speak eSCL.
- Ships Epson Scan 2 6.7.80.0, both the open core and the proprietary plugin,
  so the **Epson Perfection V39 II** (`04b8:013f`) works out of the box
  including the `esfw0282.bin` firmware the scanner needs before it responds.
  The plugin is fetched from Epson at build time, checksum-pinned, rather than
  redistributed.
- On aarch64 the entire scanning stack is armhf, AirSane included, and runs
  under the kernel's AArch32 layer. Epson never published a 64-bit ARM build of
  the closed half of the driver and no source exists to build one, so AirSane
  is cross-compiled to armhf in order to load it directly.
  This is deliberately *not* done by bridging a 64-bit AirSane to a 32-bit
  `saned`: SANE's network protocol does not interoperate across that boundary.
  Enumeration works, then the first `sane_start` desynchronises and both ends
  block forever. One word size end to end is what avoids it.
- Standard SANE backends are switched off so the proprietary driver cannot be
  confused by a backend that half-recognises the scanner.
- Gamma correction for macOS is on by default, cancelling the gamma of 1.8 that
  macOS bakes into every scan and cannot be told not to.
