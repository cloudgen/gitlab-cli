**file**: docs/requirements/requirement-domain-gitlab-cli.md
**Requirement-ID**: `RQ-DOMAIN-GITLAB-CLI`
**Status**: Active (Version 1.0.0)
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth for domain product law** of the **gitlab-cli** POSIX shell CLI: **GitLab Omnibus operator commands** (list users, reset passwords, `gitlab-ctl` status, `gitlab-adm` least privilege). It does **not** own external Nginx, Certbot, or Let's Encrypt.

**Mandatory peers (fail closed):**

| Peer | Requirement-ID | Owns |
|------|----------------|------|
| CLI interface | **RQ-SHELL-CLI-INTERFACE** | Dispatch, help routing, dual mention |
| Default interaction | **RQ-SHELL-CLI-DEFAULT-INTERACTION** | Numbered list membership |
| Zero arguments | **RQ-SHELL-CLI-ZERO-ARGUMENTS** | Empty argv split (TTY list vs Type O pipe) |
| Output | **RQ-SHELL-OUTPUT-REQUIREMENTS** | `out_*` channels |
| Sudo | **RQ-SHELL-SUDO-COMMAND** | In-tool sudo (none for rails/ctl — invoker is already root) |

**Scope:** Domain command surface, GitLab tool probes, password-reset walk, `gitlab-adm` setup/teardown, help/about domain rows.
**Out of scope:** Install / self-update / empty-argv install-ensure; full `out_*` catalog; companion digest.

**Registry role:** This is the **one Active domain-requirements SSOT** for gitlab-cli. Parallel Active domain-law files are forbidden.

**Naming law:** Domain SSOT basename is `requirement-domain-gitlab-cli.md` (subject **gitlab-cli**).

### 1.1 Human-facing

**In one sentence:** After the program is installed, you run `sudo gitlab-cli list-users` (or pick it from the numbered list) on a Linux host that already has GitLab Omnibus, so you can see accounts and reset a password without touching Nginx.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Operator with root for GitLab verbs | `sudo gitlab-cli list-users` |
| The other role | Dedicated `gitlab-adm` owns GitLab config after `setup` | `sudo gitlab-cli remove-lpu --force` |
| Not this file | Installing *this* CLI (`install`, empty argv on a pipe, `self-update`) | `gitlab-cli` with no arguments in `curl \| sh` |

| Includes | Excludes |
|----------|----------|
| `list-users`, `reset-password`, `status`, `setup`, `remove-lpu` | `nginx-conf`, `domains`, `email`, `--no-cloudflare`, external Nginx |
| Numbered user list before a password reset on a terminal | Empty argv starting GitLab mutate |

| Surface | What you open | What for |
|---------|---------------|----------|
| `sudo gitlab-cli list-users` | command | live GitLab accounts |
| `sudo gitlab-cli reset-password` | command | numbered user list, then a new password |
| `/opt/gitlab/bin/gitlab-rails` | host tool | Omnibus query (may be absent) |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| List accounts | Needs root and Omnibus. Missing `gitlab-rails` fails closed with a next step. | `sudo gitlab-cli list-users` |
| Reset a password | On a terminal the program lists users with numbers first. A wrong number reprints that user list. | `sudo gitlab-cli reset-password` |

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Specialized CLI subcommands (normative catalog)

Domain verbs **MUST** be stable unless this requirement is explicitly revised. Dispatch **MUST** run through the single CLI entry (`app_main`). Domain handlers **MUST NOT** replace Type 0 `inst_*` lifecycle.

| Command | Privilege | Handler | Operands / flags | Required behavior | Typical non-zero outcomes |
|---------|-----------|---------|------------------|-------------------|---------------------------|
| `list-users` | root | `gl_list_users` | global `--json` | Probe `gitlab-rails`; print users (id, username, email, state). JSON: count + usernames + ids | not root → fail; rails missing → fail |
| `reset-password` | root | `gl_reset_password` | optional username; env `GITLAB_NEW_PASSWORD` off-TTY | TTY: numbered user list first, pick number or username, prompt password twice (un-echoed when `stty` exists). Invalid pick **reprints this user list**. Off-TTY: username required + `GITLAB_NEW_PASSWORD`; **MUST NOT** hang | not root → fail; unknown user → fail; empty password → fail |
| `status` | root | `gl_status` | `--json` | Run `gitlab-ctl status` | not root → fail; ctl missing → fail |
| `setup` | root | `gl_setup` | `--json` | Create `gitlab-adm` (UID/GID 1888, home `/etc/gitlab-adm`), symlink `/etc/gitlab`, restricted sudoers for `gitlab-ctl` and `gitlab-rails`. **MUST NOT** install Nginx, Certbot, or `nginx-adm` | not root → fail |
| `remove-lpu` | root | `gl_remove_lpu` | `--force` | F7 teardown of **gitlab-adm** only: sudoers backup+remove; restore `/etc/gitlab` from symlink; `userdel -r`. Aliases: `remove-gitlab-adm`. **MUST NOT** accept a `nginx` target | not root → fail; non-TTY without `--force` → fail |

**Complete invocation samples (topic-owner — dual mention):**

```text
sudo gitlab-cli list-users
sudo gitlab-cli --json list-users
sudo gitlab-cli reset-password
sudo gitlab-cli reset-password root
GITLAB_NEW_PASSWORD=… sudo gitlab-cli reset-password root
sudo gitlab-cli status
sudo gitlab-cli setup
sudo gitlab-cli remove-lpu --force
sudo gitlab-cli remove-gitlab-adm --force
```

**Dispatch rules:**

1. Domain commands **MUST** be recognized in the same global flag parse pass as Type 0 lifecycle commands.
2. Empty argv **MUST NOT** run domain mutate — empty argv is owned by `requirement-shell-cli-zero-arguments` (TTY numbered list / Type O pipe).
3. All user-facing domain messages **MUST** go through centralized `out_*`.
4. Type 0 routes remain available after domain specialization.
5. **`remove-lpu` is not** Type 0 `self-uninstall`.
6. Usernames passed to `gitlab-rails` **MUST** match `^[A-Za-z0-9_.][A-Za-z0-9_.-]*$`.
7. The new password **MUST NOT** be printed on stdout/stderr or written into logs.

### 2.2 Specialized features (normative)

#### 2.2.1 GitLab tools

| Tool | Probe order |
|------|-------------|
| `gitlab-rails` | `GITLAB_RAILS` if executable; `command -v gitlab-rails`; `/opt/gitlab/bin/gitlab-rails`; `/usr/bin/gitlab-rails` |
| `gitlab-ctl` | `GITLAB_CTL` if executable; `command -v gitlab-ctl`; `/opt/gitlab/bin/gitlab-ctl`; `/usr/bin/gitlab-ctl` |

Missing tool → fail closed with **Next:** pointing at install GitLab CE / the matching verb.

#### 2.2.2 List users (sample body — this product)

Human lines: `id  username  email  state` from:

```ruby
User.order(:id).find_each { |u| puts [u.id, u.username, u.email, u.state].join("\t") }
```

JSON success includes `count`, `usernames`, `ids`, `rails`.

#### 2.2.3 Reset password (sample body — this product)

Password is passed in process env `GITLAB_NEW_PASSWORD` (and `GL_USER`), **not** interpolated into the runner argv string:

```ruby
u=User.find_by_username(ENV["GL_USER"]); abort("missing") unless u
u.password=ENV["GITLAB_NEW_PASSWORD"]
u.password_confirmation=ENV["GITLAB_NEW_PASSWORD"]
u.password_automatically_set=false
u.save!
```

The TTY user picker is a **menu layer**: invalid choice **MUST** `out_error`, reprint **this** numbered user list, and re-prompt. **MUST NOT** `out_die` on a typo. Exit / empty / `quit` leaves that layer without resetting.

#### 2.2.4 gitlab-adm

| Artifact | Path (this product) |
|----------|---------------------|
| Account | `gitlab-adm` UID/GID **1888**, home `/etc/gitlab-adm`, shell `/bin/bash` |
| Real config | `/etc/gitlab-adm/gitlab` |
| Public path | `/etc/gitlab` symlink |
| Sudoers | `/etc/sudoers.d/gitlab-adm` — NOPASSWD `gitlab-ctl` and `gitlab-rails` absolute paths |

**MUST NOT** create `nginx-adm`. **MUST NOT** write `/etc/nginx`.

#### 2.2.5 Non-goals

- Replacing Omnibus GitLab with source installs
- External Nginx / Certbot / Let's Encrypt / Cloudflare SSH hostname
- Empty argv domain mutate

### 2.3 Specialized project help items

`help` **MUST** list domain rows:

- `list-users`
- `reset-password`
- `status`
- `setup`
- `remove-lpu` / `remove-gitlab-adm`

Plus Type 0 self-management and `menu` / `main`. **MUST NOT** list `nginx-conf`, `domains`, `email`, `--no-cloudflare`.

### 2.4 Specialized project about items

`about` **MUST** expose:

- `gitlab-ctl` path (or not found)
- `gitlab-rails` path (or not found)
- whether `gitlab-adm` exists
- useful command reminders for list-users / reset-password / status

JSON **MUST** include `gitlab_ctl`, `gitlab_rails`, `gitlab_adm`, `domain`=`gitlab-cli`. **MUST NOT** include `domains_file` / `email_file`.

### 2.5 Implementation Notes (this project)

| Item | Value |
|------|--------|
| **Product / binary** | `gitlab-cli` (`APP_NAME`) |
| **Ship unit** | Repo root `./gitlab-cli` |
| **Channel** | `cloudgen/gitlab-cli` |
| **Prefix** | Domain handlers `gl_*` |
| **Menu rows (operational)** | `list-users`, `reset-password`, `status`, `remove-lpu` (`setup` is live but **not** a main-menu row) |

## 3. Acceptance criteria (summary)

| ID | Criterion |
|----|-----------|
| AC-D1 | `gitlab-cli version` / `help` / `about` work under Type 0 + domain |
| AC-D2 | Empty argv does **not** start GitLab mutate |
| AC-D3 | `list-users` / `reset-password` / `status` / `setup` / `remove-lpu` are routed; non-root fail-closed |
| AC-D4 | Help omits Nginx verbs |
| AC-D5 | Bootstrap **selfmanaged** ship unit is never overwritten by this product |

## Under command line for normal user only

When this program runs on Termux, Git Bash, Windows Command Prompt, or the same class: **admin privilege** and **dedicated system user privilege** are unused. Do not wrap `sudo`, do not wrap Linux `apt`/`dnf`, do not create `gitlab-adm`, and do not recommend `sudo curl | sh`. Git Bash and Windows cmd must not invoke Termux `pkg`.

**This requirement:** `list-users`, `reset-password`, `status`, `setup`, and `remove-lpu` are unused on that class.

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-GITLAB-CLI-01…10** | `tests/test_domain.sh` | have |
| Host-mutating rails/ctl against live Omnibus | optional | optional |

**Map:** `reviews/test-plan.md`.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Reintroduce Nginx / Certbot / Let's Encrypt / `nginx-adm` as this product's domain.
2. Route empty argv to GitLab mutate.
3. Echo the new password.
4. Pass unsanitized usernames into `gitlab-rails`.
5. `out_die` on a typo in the reset-password user list (that list is a menu layer).
6. Treat `remove-lpu` as CLI uninstall.

## 5. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention of domain verbs |
| `docs/requirements/requirement-shell-cli-default-interaction.md` | Numbered list |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Empty argv split |
| `docs/requirements/requirement-shell-sudo-command.md` | In-tool sudo (none for rails — already root) |
| `./gitlab-cli` | Implementation under test |

**Last Updated**: 2026-09-13
**Owner**: gitlab-cli project maintainers
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
