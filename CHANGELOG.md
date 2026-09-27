# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-09-27

### Changed
- **Cache folder.** Each login and each process gets its own leaf. Linux: `/dev/shm/cache/cache-gitlab-cli-${login}-$$`, then `/tmp/cache/cache-gitlab-cli-${login}-$$`, then `${HOME}/.cache/cache-gitlab-cli-$$`. Git Bash: `/tmp/cache/cache-gitlab-cli-${login}-$$`, then `${HOME}/AppData/Local/Temp/cache-gitlab-cli-$$`. Mac: `/tmp/cache/cache-gitlab-cli-${login}-$$`, then `${HOME}/Library/Caches/cache-gitlab-cli-$$`, then `${HOME}/cache/cache-gitlab-cli-$$`. Skipping a tier prints no warning and no error. `about` prints **Cache folder used**, **preferred**, **1st fallback**, and **2nd fallback** when that host has one, plus **Persistence storage** `${HOME}/.local/gitlab-cli`. Law: `requirement-shell-cli-storage` **1.2.0**. Suite **TP-CLI-04** · **TP-CLI-05**.

## [1.0.0] - 2026-09-13

### Added
- **gitlab-cli** public baseline: POSIX `/bin/sh` GitLab **operator** CLI (install yourself, then list users / reset passwords / `gitlab-ctl status`).
- **Numbered main menu** on a real terminal: empty argv or `menu` / `main`. Labels: `list-users`, `reset-password`, `status`, `remove-lpu`. Exit **9**. A wrong number prints an error and **reprints the list**.
- **`list-users`** — root; Omnibus `gitlab-rails runner` TSV list (JSON count + usernames).
- **`reset-password`** — root; numbered GitLab user list first on a terminal; non-interactive needs a username + `GITLAB_NEW_PASSWORD`.
- **`status`** — root; `gitlab-ctl status`.
- **`setup` / `remove-lpu`** — `gitlab-adm` least-privilege only (`gitlab-ctl` + `gitlab-rails` sudoers). No `nginx-adm`.
- Channel `cloudgen/gitlab-cli`; automatic SHA-256 companion `gitlab-cli.sha256`.

### Removed
- External **Nginx**, **Certbot**, Let's Encrypt `domains` / `email`, `nginx-conf`, `--no-cloudflare`, Cloudflare SSH hostname, `nginx-adm`, and the 13-step GitLab+Nginx host installer (`run`).

### Changed
- Empty argv: **pipe / script** still Type O install-ensure; **real terminal** opens the numbered list. `--json` with no command is JSON help.
- Ship unit is `./gitlab-cli` (origin product was `gitlab-nginx`).
