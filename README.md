# Potochi's Home Assistant Apps

A collection of Home Assistant apps (add-ons).

| App | Folder | Description |
|-----|--------|-------------|
| **TFTP Server** | [`tftp/`](tftp/) | Serves files over TFTP from a folder inside `/share`, manageable over NFS/Samba. Optional uploads. |
| **Calibre Server** | [`calibre-server/`](calibre-server/) | Headless Calibre content server for your e-book library. |
| **CUPS** | [`cups-airprint/`](cups-airprint/) | CUPS print server with working AirPrint. |

## Installation

1. In Home Assistant go to **Settings → Apps → App Store → ⋮ → Repositories**
   and add this repository's git URL.
2. Install the app(s) you want and start them.

Alternatively, copy an app folder into the `/addons` directory of your
Home Assistant installation and reload the App Store; it appears under
**Local apps**.

Each app's documentation lives in its folder (`DOCS.md`).
