# Changelog

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
