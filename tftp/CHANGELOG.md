# Changelog

## 1.0.0

- Initial release.
- Serves `/share/<directory>` (default `/share/tftp`) over TFTP on UDP
  port 69 (host network), powered by tftp-hpa on Alpine 3.23.
- Optional uploads (`allow_uploads`), per-transfer logging (`verbose`),
  and raw `in.tftpd` flags (`extra_args`).
