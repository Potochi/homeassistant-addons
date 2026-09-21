# Scanner Server

Shares a USB scanner with the rest of the network over **AirScan/eSCL** - the
scanning counterpart to AirPrint.

Scanners appear on their own in macOS Image Capture and Preview, on iOS, in
Windows 10/11, in the Mopria app on Android, and through `sane-airscan` on
Linux. Nothing has to be installed on the clients.

- Ships Epson's proprietary driver, so an **Epson Perfection V39 II** works out
  of the box, including the firmware the scanner needs before it answers at all
- A web interface on port 8090 for anything that cannot speak eSCL
- Runs the whole scanning stack at one word size, which on 64-bit ARM means
  armhf throughout - the only arrangement that actually works, see DOCS.md

Only the V39 II is verified. Other Epson models covered by Epson Scan 2 are
very likely to work; non-Epson scanners are not supported by this add-on.

See [DOCS.md](DOCS.md) for setup, per-client instructions and every option.
