# TFTP Server

Serves files over TFTP (UDP port 69) from a folder inside Home Assistant's
`share` folder.

Because the files live under `/share`, you can manage them from another
machine over NFS or Samba (e.g. with the NFS/Samba share apps): drop a file
into the folder and it is served immediately.

## How it works

- The app runs [tftp-hpa](https://www.kernel.org/pub/software/network/tftp/)
  chrooted into `/share/<directory>` (default: `/share/tftp`). The folder is
  created automatically on first start.
- It uses the host network because TFTP transfers data from ephemeral UDP
  ports, which does not survive container port mapping. Make sure nothing
  else on the host uses UDP port 69.
- The server drops privileges to `nobody` after binding the port.

## Configuration

```yaml
directory: tftp
allow_uploads: false
verbose: true
```

### Option: `directory`

Subfolder of `/share` to serve, e.g. `tftp` serves `/share/tftp`.
Nested paths like `tftp/firmware` are allowed; `..` is not.

### Option: `allow_uploads`

When `true`, TFTP clients may upload (create and overwrite) files.
To make this work for the unprivileged server, the folder is made
world-writable (`0777`) and uploaded files are created world-readable
(`0666`), so they stay accessible over NFS. Leave this off unless you
need it (e.g. network gear pushing config backups).

### Option: `verbose`

When `true` (default), each transfer is logged to the app log
(`RRQ` = download, `WRQ` = upload).

### Option: `extra_args` (optional)

Extra command-line arguments passed verbatim to `in.tftpd`, e.g.
`--blocksize 1468 --retransmit 2000000`. See `man in.tftpd` for the full
list.

## Notes

- **Downloads require world-readable files.** Files you create over NFS are
  usually `644` which is fine; if a transfer fails with "Permission denied",
  check the file mode.
- TFTP has no authentication or encryption — only run it on a trusted LAN.
- Quick test from any machine: `curl tftp://homeassistant.local/myfile.bin`
  (or `tftp homeassistant.local` with get/put).
