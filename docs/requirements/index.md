# Requirements index

**Product:** gitlab-cli (POSIX `/bin/sh` CLI + GitLab operator domain)  
**Workspace state:** Specialized product law (not blank genesis); **software-development class** + **domain SSOT present**.  
**Class law:** `requirement-class-software-dev` / **`RQ-CLASS-SOFTWARE-DEV`**.  
**Domain SSOT:** `requirement-domain-gitlab-cli` / **`RQ-DOMAIN-GITLAB-CLI`**.  
**Bootstrap origin:** selfmanaged Type 0 (A→B specialize); product **stripped from gitlab-nginx** (Nginx / Certbot removed).  
**Updated:** 2026-09-27

| Requirement-ID | Key | Title | Area | Status | Path | Updated |
|----------------|-----|-------|------|--------|------|---------|
| `RQ-CLASS-SOFTWARE-DEV` | requirement-class-software-dev | Software-development class law + residual stack (posix-sh Type 0) | class | Active | `requirement-class-software-dev.md` | 2026-09-13 |
| `RQ-SHELL-AUTOMATIC-CHECKSUM` | requirement-shell-automatic-checksum | Automatic companion-digest integrity (transparent link/value/result; CHECKSUM not help/about) | shell | Active | `requirement-shell-automatic-checksum.md` | 2026-09-13 |
| `RQ-SHELL-CLI-INTERFACE` | requirement-shell-cli-interface | Shell CLI interface (commands, flags, dispatch, modes) | shell | Active | `requirement-shell-cli-interface.md` | 2026-09-13 |
| `RQ-SHELL-CLI-DEFAULT-INTERACTION` | requirement-shell-cli-default-interaction | TTY numbered list (empty argv overlay + menu/main; invalid choice retries) | shell | Active | `requirement-shell-cli-default-interaction.md` | 2026-09-13 |
| `RQ-SHELL-CLI-STORAGE` | requirement-shell-cli-storage | Per-login per-process cache folder (Linux shm → tmp → `~/.cache`; Git Bash tmp → AppData; Mac tmp → Library/Caches → `~/cache`) and persistence `${HOME}/.local/${APP_NAME}`; silent tier miss | shell | Active | `requirement-shell-cli-storage.md` | 2026-09-27 |
| `RQ-SHELL-CLI-ZERO-ARGUMENTS` | requirement-shell-cli-zero-arguments | Empty argv: TTY numbered list; off-TTY Type O install-ensure; `--json` JSON help | shell | Active | `requirement-shell-cli-zero-arguments.md` | 2026-09-13 |
| `RQ-DOMAIN-GITLAB-CLI` | requirement-domain-gitlab-cli | GitLab operator domain (list-users/reset-password/status/setup/remove-lpu; help + about pillars) | domain | Active | `requirement-domain-gitlab-cli.md` | 2026-09-13 |
| `RQ-SHELL-IDEMPOTENCY` | requirement-shell-idempotency | Shell idempotency / re-run safety for ensure-style ops | shell | Active | `requirement-shell-idempotency.md` | 2026-09-13 |
| `RQ-SHELL-INTERACTIVE-VS-NONINTERACTIVE` | requirement-shell-interactive-vs-noninteractive | Interactive vs non-interactive / `curl\|sh` behavior | shell | Active | `requirement-shell-interactive-vs-noninteractive.md` | 2026-09-13 |
| `RQ-SHELL-MODULAR-FUNCTION-DESIGN` | requirement-shell-modular-function-design | Single-file modular function design (prefixes, zones) | shell | Active | `requirement-shell-modular-function-design.md` | 2026-09-13 |
| `RQ-SHELL-OUTPUT-REQUIREMENTS` | requirement-shell-output-requirements | Central `out_*` output SSOT (stdout/stderr, modes; `@key` raw nested/numeric JSON) | shell | Active | `requirement-shell-output-requirements.md` | 2026-09-13 |
| `RQ-SHELL-SELF-MANAGEMENT` | requirement-shell-self-management | Self-management lifecycle (version-check, update, uninstall, about) | shell | Active | `requirement-shell-self-management.md` | 2026-09-13 |
| `RQ-SHELL-SCRIPT-CODING` | requirement-shell-script-coding | POSIX `/bin/sh` coding style (specialize-in home; without it, lessons arrive raw) | shell | Active | `requirement-shell-script-coding.md` | 2026-09-13 |
| `RQ-SHELL-SUDO-COMMAND` | requirement-shell-sudo-command | In-tool sudo wrap + studied allow table (none after nginx strip; check_root for GitLab verbs) | shell | Active | `requirement-shell-sudo-command.md` | 2026-09-13 |

**Rules for agents:**

1. Treat rows above as the **live product-law inventory** for gitlab-cli.  
2. **Primary citation** uses **Requirement-ID** (`RQ-*`) on product surfaces; path/basename secondary.  
3. **Do not invent** additional `requirement-*.md` paths — verify on disk and add a registry row in the same change when creating one.  
4. Product source comments cite **only** these live requirements — never `template-*` / `skill-*` as behavioral authority.  
5. **Bootstrap direction:** selfmanaged (A) → gitlab-cli (B) only; never reverse-copy B onto A.  
6. **Class gate:** software-development requires exactly one Active `requirement-class-software-dev.md`.  
7. **Domain gate:** exactly one Active `requirement-domain-*` SSOT.

When adding a requirement: append a row, create the file under `docs/requirements/`, keep Status in sync with the file header.
