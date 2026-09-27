# gitlab-cli - GitLab operator CLI (list users, reset passwords)

![Version](https://img.shields.io/badge/Version-1.0.1-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
[![CIAO](https://img.shields.io/badge/Philosophy-CIAO%20(Caution%20%E2%80%A2%20Intentional%20%E2%80%A2%20Anti--fragile%20%E2%80%A2%20Over--engineered)-purple.svg)](https://github.com/cloudgen/ciao)
[![Stars](https://img.shields.io/github/stars/cloudgen/gitlab-cli?style=flat-square)](https://github.com/cloudgen/gitlab-cli)
[![Shell](https://img.shields.io/badge/Shell-POSIX%20sh-orange?style=flat-square)]()

You put one program file (`gitlab-cli`) on a Linux host that already runs **GitLab Omnibus**, then use it as yourself for install/update, and as root for **list users**, **reset a user password**, and **gitlab-ctl status**. This is **not** the old gitlab-nginx installer: it does **not** install external Nginx, Certbot, or Let's Encrypt.

| Who | Meaning | Example |
|-----|---------|---------|
| **You** | A person who can install this program as yourself. GitLab operator commands need a root login. | `curl … \| sh` then `sudo gitlab-cli list-users` |
| **The other role** | After `setup`, dedicated account `gitlab-adm` owns GitLab config under `/etc/gitlab-adm` — not your daily login. | `remove-lpu` tears that account down |
| **Not this** | External Nginx, Certbot, domain files, or Cloudflare SSH hostname. Empty `gitlab-cli` on a **pipe** means **install this program**. On a **real terminal**, empty argv opens the **numbered list**. | `gitlab-cli` with no arguments |

| Includes | Excludes |
|----------|----------|
| List GitLab users; reset a password from a numbered user list; `gitlab-ctl status` | External Nginx reverse proxy, Certbot, `nginx-conf`, `domains`, `email` |
| Install for yourself (`~/.local/bin`) or for everyone (`/usr/local/bin`) | Treating empty argv in a pipe as help or as a GitLab mutate |
| Automatic SHA-256 companion check on download | Requiring a `CHECKSUM=` pin for every install |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Install the program | Downloads `gitlab-cli` and places it on your PATH. Does **not** change GitLab yet. | `curl -fsSL https://raw.githubusercontent.com/cloudgen/gitlab-cli/main/gitlab-cli \| sh` |
| Open the numbered list | On a real terminal, no arguments (or `menu`) shows live work commands. A wrong number reprints the list. | `gitlab-cli` |
| List or reset users | Needs root and Omnibus `gitlab-rails`. Reset always lists users first on a terminal. | `sudo gitlab-cli list-users` |

This project follows [CIAO](https://github.com/cloudgen/ciao) (Caution • Intentional • Anti-fragile • Over-engineered).

## Features

- **Self-installing program file** — user-local (`~/.local/bin`) or global (`/usr/local/bin`)
- **Automatic SHA-256 companion check** — the program fetches `gitlab-cli.sha256` itself (no env pin required)
- **Numbered main menu** on a real terminal (empty argv or `menu` / `main`); a wrong choice reprints the list
- **`list-users`** — print GitLab users via `gitlab-rails runner`
- **`reset-password`** — numbered GitLab user list first, then set a new password
- **`status`** — `gitlab-ctl status`
- **`setup` / `remove-lpu`** — `gitlab-adm` least-privilege operator only (no `nginx-adm`)
- **Safe to re-run** install and ensure-style steps
- **Idempotent CLI lifecycle** — `version-check`, `self-update`, `self-uninstall`

## Quick Installation

Install the program (does not change GitLab):

```bash
# For yourself → ~/.local/bin/gitlab-cli
curl -fsSL https://raw.githubusercontent.com/cloudgen/gitlab-cli/main/gitlab-cli | sh
```

```bash
# For everyone → /usr/local/bin/gitlab-cli
sudo curl -fsSL https://raw.githubusercontent.com/cloudgen/gitlab-cli/main/gitlab-cli | sudo sh
```

The channel URL is the product default (`SCRIPT_URL`). Override that env only if you fork the channel.

### Integrity (automatic SHA-256)

When you do **not** set `CHECKSUM`, the program downloads the companion digest itself from `${SCRIPT_URL}.sha256` (in-repo file: `gitlab-cli.sha256`). Human mode is designed to show the **link** (companion URL), the **value** (expected digest), and the **result**.

| Outcome | What happens |
|---------|----------------|
| Companion found and digest **matches** | Install continues |
| Companion found and digest **mismatches** | Install **aborts** |
| Companion **missing** | **Warning**, then install continues (best-effort) |

Algorithm: **SHA-256** (`sha256sum`). Same-channel companion files prove the two files on that channel match. They are not a substitute for signed releases.

### After install — numbered list

On a **real terminal**, running with **no arguments** (or `gitlab-cli menu`) opens the numbered list of live work commands. Install, setup, version, about, help, and self-update are **not** on this list — they stay on `help`. Choose a number or a command name. A wrong number prints an error and **shows the list again**. `9` exits.

```text
$ gitlab-cli
[INFO] **gitlab-cli**(*1.0.1*) — numbered list of live work commands
1. list-users: List GitLab users
2. reset-password: Reset a GitLab user password (numbered list first)
3. status: Show gitlab-ctl status
4. remove-lpu: Remove gitlab-adm (confirm or --force)
9. Exit
```

Choose a number, or type the command name. `9` exits.

A **pipe** (`curl | sh`) with no arguments still **installs this program**. It does not open the list and does not mutate GitLab.

### Advanced: optional digest pin (CI)

Optional process env — **not** listed in `help` / `about`, **not** the primary newcomer path. Paste the current `gitlab-cli.sha256` hex (do not copy a stale hash from old docs):

```bash
CHECKSUM=<64-hex-from-gitlab-cli.sha256> \
  curl -fsSL https://raw.githubusercontent.com/cloudgen/gitlab-cli/main/gitlab-cli | sh
```

Regenerate the in-repo companion after editing `./gitlab-cli`: `sha256sum gitlab-cli | cut -d' ' -f1 > gitlab-cli.sha256`. Do not paste a same-origin `CHECKSUM=$(curl …sha256)` as “higher assurance” than automatic mode.

## Usage

```text
gitlab-cli [command] [options]
```

| Command | Who may run it | What it does |
|---------|----------------|--------------|
| *(no arguments, real terminal)* | You | Numbered list of live work commands |
| *(no arguments, pipe / script)* | You | Install or re-check this program |
| `menu` (alias `main`) | You | Same numbered list on a terminal; help in a script |
| `install` | You (root → global path) | Place the CLI binary |
| `version` | You | Print version |
| `about` | You | Diagnostics (install, cache folder, persistence storage, GitLab tools) |
| `help` | You | Full usage |
| `version-check` | You | Compare local vs channel version |
| `self-update` | You | Update this program from the channel |
| `self-uninstall` | You | Remove this program (not GitLab, not `gitlab-adm`) |
| `list-users` | Root | List GitLab users |
| `reset-password [user]` | Root | Numbered user list first (terminal), then reset that password |
| `status` | Root | `gitlab-ctl status` |
| `setup` | Root | Create `gitlab-adm` (no Nginx) |
| `remove-lpu` | Root | Remove `gitlab-adm` (`userdel -r`) |

**Global options:** `--quiet` / `-q`, `--json`, `--force` (`--reset` / `--reinstall` same), `--debug`

**Environment (listed in help):** `REPO_USER`, `REPO_NAME`, `SCRIPT_URL`. `CHECKSUM` is an install-path pin only — not a help/about field. Non-interactive password reset uses process env `GITLAB_NEW_PASSWORD` (not listed in help).

## Examples

```bash
gitlab-cli version
gitlab-cli about
gitlab-cli --json about
gitlab-cli menu
sudo gitlab-cli list-users
sudo gitlab-cli reset-password
sudo gitlab-cli status
sudo gitlab-cli setup
sudo gitlab-cli remove-lpu --force
gitlab-cli help
```

## Platform Compatibility

| Surface | Status |
|---------|--------|
| Ubuntu 20.04 / 22.04 / 24.04 with Omnibus GitLab | Supported for list-users / reset-password / status |
| Other Debian-based Linux with `/bin/sh`, `curl` or `wget`, `sha256sum` | CLI install and self-update |
| Termux / Git Bash / Windows Command Prompt | CLI self-install as yourself only — no GitLab host mutate, no dedicated system users, no `sudo curl \| sh` |
| Host without Omnibus `gitlab-rails` / `gitlab-ctl` | Operator verbs fail closed with a next step |

Full GitLab operator verbs need root. Non-interactive `reset-password` needs a username operand (and `GITLAB_NEW_PASSWORD`); it does not hang.

## Related Projects

- [CIAO](https://github.com/cloudgen/ciao) — defensive programming philosophy this CLI follows
- [selfmanaged](https://github.com/cloudgen/selfmanaged) — Type 0 bootstrap this product specialized from (install / version-check / self-update / self-uninstall)
- Origin product (external Nginx + GitLab): [gitlab-nginx](https://github.com/Wilgat/gitlab-nginx) — this CLI **strips** that Nginx surface

## Contributing

Contributions are welcome. Open an issue or a pull request. Keep install, checksum, and privilege behavior honest in `README.md` and `CHANGELOG.md` when you change them.

## License

MIT License. See [LICENSE.md](LICENSE.md).

## Last Update

2026-09-27 — **1.0.1**: cache folder is per login and per process (Linux `/dev/shm/cache`, then `/tmp/cache`, then `~/.cache`). `about` names the folder in use and each fallback. Persistence stays `~/.local/gitlab-cli`.

2026-09-13 — **1.0.0**: gitlab-cli public baseline. Stripped from gitlab-nginx (no external Nginx / Certbot). Numbered main menu on a real terminal; `list-users` and `reset-password`.
