# CGit Server — Documentation

Browse your git repositories in a web UI with [cgit](https://git.zx2c4.com/cgit/about/)
and push to them over SSH using a shared set of public keys. The repositories
live in a folder inside `/share`, so you can also reach them over NFS or Samba
(e.g. with the Samba/NFS share add-ons).

## Quick start

1. Install and start the add-on once (this generates the SSH host keys).
2. Add your SSH **public** key(s) to the `push_keys` option (see below).
3. Restart the add-on.
4. Push a repository:

   ```sh
   cd my-project
   git remote add origin ssh://git@homeassistant.local:2222/my-project.git
   git push -u origin HEAD
   ```

   With `auto_init` on (the default) the bare repository is created on the
   first push. It immediately appears in the web UI.
5. Open the web UI from the add-on page (or `http://homeassistant.local:8087/`)
   to browse it.

## How it works

- **Web interface** — `lighttpd` serves `cgit.cgi` on port `80` (mapped to host
  `8087` by default). cgit scans `/share/<repos_dir>` for bare repositories and
  renders the browser, log, tree, diff, commit graph and snapshots.
- **Clone/fetch over HTTP** — smart HTTP is handled by `git-http-backend`.
  This is **read-only**: pushing over HTTP is refused (HTTP `403`), so pushes
  always go through SSH.
- **Push/fetch over SSH** — `sshd` on port `22` (mapped to host `2222`) accepts
  only the `git` user, authenticated by the keys in `push_keys`. Every key in
  the list can push and fetch **every** repository — there is no per-repo access
  control, by design. Interactive shell logins are refused; the account only
  runs `git-receive-pack` / `git-upload-pack`.

## Options

```yaml
repos_dir: git
push_keys:
  - "ssh-ed25519 AAAA... you@laptop"
auto_init: true
root_title: Git repositories
root_desc: Hosted on Home Assistant
clone_url_ssh: "ssh://git@homeassistant.local:2222"
enable_http_clone: true
fix_permissions: true
git_uid: 1000
git_gid: 1000
extra_cgitrc: ""
```

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `repos_dir` | str | `git` | Subfolder of `/share` that holds the bare repositories, e.g. `git` serves `/share/git`. Nested paths are allowed; `..` is not. Created on first start. |
| `push_keys` | list | `[]` | SSH **public** keys allowed to push and fetch over SSH. One line per key, in `authorized_keys` format. All keys have full access to all repositories. |
| `auto_init` | bool | `true` | Create a bare repository automatically on the first push to a name that does not exist yet. When `false`, pushing to a missing repo is refused. |
| `root_title` | str | `Git repositories` | Heading shown at the top of the cgit index page. |
| `root_desc` | str | `Hosted on Home Assistant` | Sub-heading under the title. |
| `clone_url_ssh` | str | `""` | SSH base URL advertised on each repo's page. The repo path is appended, so `ssh://git@homeassistant.local:2222` becomes `ssh://git@homeassistant.local:2222/foo.git`. Leave blank to hide the SSH clone URL. |
| `enable_http_clone` | bool | `true` | Serve read-only clone/fetch over HTTP and advertise the HTTP clone URL. |
| `fix_permissions` | bool | `true` | On start, `chown` the repository folder to the `git` user so pushes can write. Turn off if you manage ownership yourself. |
| `git_uid` | int | `1000` | UID of the `git` service user. Set it to match the owner your NFS/Samba clients use if you want consistent ownership on `/share`. |
| `git_gid` | int | `1000` | GID of the `git` service user. |
| `extra_cgitrc` | str | `""` | Extra lines appended verbatim to the generated `cgitrc` (before `scan-path`). Use for cgit settings not exposed as options, e.g. `enable-blame=1`. |

## Getting your public key

On the machine you push from:

```sh
cat ~/.ssh/id_ed25519.pub      # or id_rsa.pub
# ssh-ed25519 AAAAC3Nza... you@laptop
```

Paste that whole line into `push_keys`. If you don't have a key yet,
`ssh-keygen -t ed25519` creates one. Never paste a **private** key.

## Networking

The add-on uses two mapped ports (bridge networking, no `host_network`):

| Container port | Default host port | Purpose |
| --- | --- | --- |
| `80/tcp` | `8087` | cgit web interface + HTTP clone |
| `22/tcp` | `2222` | Git over SSH (push/fetch) |

Change the host ports under the add-on's **Network** section. If you change the
SSH host port, update `clone_url_ssh` to match so the advertised clone URLs are
correct. Port `2222` avoids clashing with Home Assistant OS's own SSH add-on on
`22`.

The first time a client connects over SSH it will prompt to trust the host key.
Host keys are stored in `/data/ssh` and persist across restarts and updates, so
the fingerprint only has to be accepted once.

## Repositories on the host

Bare repositories live under `/share/<repos_dir>` (default `/share/git`). Because
they are on `/share` you can:

- Back them up like any other file.
- Reach them over NFS/Samba to seed a repo (drop a bare repo folder in and it
  appears in cgit immediately) or to inspect them.
- Give a repo a description or default branch by editing its `description` file
  or `HEAD`.

To pre-create a repo without pushing, make a bare repo in the folder:

```sh
git init --bare /share/git/my-project.git
```

### Permissions and NFS/Samba

Pushes are written by the `git` user (`git_uid`/`git_gid`, default `1000:1000`).
If other machines write into `/share/<repos_dir>` over NFS/Samba with a different
UID, git may complain about "dubious ownership"; the add-on already marks all
repositories as safe, so cgit and SSH keep working. For consistent on-disk
ownership, set `git_uid`/`git_gid` to match your share's mapping and leave
`fix_permissions` on.

## Access model

This add-on intentionally keeps access **coarse**: any key in `push_keys` can
read and write every repository. There is no per-user or per-repo control. It is
meant for a home LAN / a small trusted group. If you expose it beyond that,
front it with a VPN or reverse proxy and treat the SSH keys as the only gate.

## Troubleshooting

- **`Permission denied (publickey)` on push** — the key isn't in `push_keys`, or
  you added the private key by mistake. Paste the `.pub` line and restart.
- **`repository '...' does not exist`** — `auto_init` is off and the repo hasn't
  been created. Enable `auto_init` or create the bare repo under `/share`.
- **HTTP clone shows an empty repo right after the first push** — fixed
  automatically: the add-on repoints a fresh repo's `HEAD` at the branch you
  pushed. If you seeded a bare repo manually, set its `HEAD` to an existing
  branch (`git symbolic-ref HEAD refs/heads/main`).
- **Push over HTTP fails** — that's intended; HTTP is read-only. Push over SSH.
