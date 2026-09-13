**file**: docs/requirements/requirement-shell-sudo-command.md  
**Requirement-ID**: `RQ-SHELL-SUDO-COMMAND`  
**Status**: Active (Version 1.0.0)  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth for in-tool `sudo`** in `./gitlab-cli`: every wrap, the **studied** allow table (binary, verb, operand, dest, NOPASSWD), and check-before-sudo.

**Scope:** Call sites inside the ship unit that invoke `sudo`; argv they may pass; fail-closed when not permitted.  
**Out of scope:** Writing `/etc/sudoers.d/*` fragments for `gitlab-adm` (domain setup owns those files); operator typing `sudo gitlab-cli list-users` in a shell (that is the human prefix, not an in-tool wrap).

### 1.1 Human-facing

**In one sentence:** When this program itself runs `sudo`, it may only run the commands in the table below — not a free-form root shell.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | You already started setup as root (`sudo gitlab-cli run`) | root session |
| The other role | Dedicated `gitlab-adm` may run allowlisted `gitlab-ctl` after setup | `gitlab-ctl status` |
| Not this file | The sudoers **files** created for those dedicated accounts | domain requirement |

| Includes | Excludes |
|----------|----------|
| `check_root` then `gitlab-rails` / `gitlab-ctl` as root | Guessing `/etc/{{username}}/{{service}}` as dest |
| Check before sudo | `sudo true` / `sudo mkdir` as grant proof |
| Fail closed if wrap is needed and not root | Treating `sudo gitlab-cli` in help text as an in-tool wrap |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./gitlab-cli` | program file | live `sudo` lines |
| `sudo gitlab-cli run` | command | host setup that reaches those lines |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| List GitLab users | You already started as root. The program calls `gitlab-rails` directly — it must not invent extra sudo argv. | `sudo gitlab-cli list-users` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Wrap discipline

1. **MUST** treat every in-tool `sudo` as a wrap: check identity/need first; then invoke only an allow-listed argv.  
2. **MUST NOT** probe `sudo true`, `sudo mkdir`, or `sudo cp` as proof of a grant.  
3. **MUST NOT** guess dest or argv. Fill the allow table from ship-unit study (this product does not ship a `print-sudoers` CLI).  
4. Help text that tells a **human** to type `sudo gitlab-cli …` is **not** an in-tool wrap.

### 2.2 Studied sudo allow table (this product)

Study evidence: `./gitlab-cli` greps for `sudo ` in domain handlers. Operator verbs `list-users` / `reset-password` / `status` / `setup` / `remove-lpu` **MUST** `check_root` first and then invoke `gitlab-rails` / `gitlab-ctl` **directly as root** — they are **not** in-tool `sudo` wraps. Dedicated-account fragment `/etc/sudoers.d/gitlab-adm` is domain-owned.

| Binary | Verb / argv | Operand | Runas | Fragment dest | NOPASSWD? | This wrap? | Study evidence |
|--------|-------------|---------|-------|---------------|-----------|------------|----------------|
| *(none)* | — | — | — | — | — | **no** | No in-tool `sudo` call site after the nginx strip. Human prefix `sudo gitlab-cli list-users` is **not** a wrap |

**MUST NOT** add `backup *`, restore, chmod of unrelated trees, or a harness dest `/etc/{{username}}/{{service}}` for these wraps.

### 2.3 Check before sudo

1. Domain mutating commands **MUST** `check_root` (or equivalent) before host mutation.  
2. **MUST NOT** invent `sudo -u gitlab-adm` wraps until a studied allow-table row exists.  
3. Non-root `list-users` / `reset-password` / `status` / `setup` / `remove-lpu` **MUST** fail closed without partial sudo.

### 2.4 Implementation Notes (this project)

| Item | Value |
|------|--------|
| `util_sudo` helper | **Gap** — live sites call `sudo` directly; future wrap **SHOULD** centralize without changing argv |
| Operator prefix in help | Human `sudo gitlab-cli list-users` — not a wrap |
| Dedicated sudoers files | Owned by `requirement-domain-gitlab-cli` (`gitlab-adm` only) |

## Under command line for normal user only

When this program runs on Termux, Git Bash, Windows Command Prompt, or the same class: **admin privilege** and **dedicated system user privilege** are unused. **MUST NOT** implement or enable in-tool `sudo`, wrap `apt`/`dnf`, create dedicated system users, or recommend `sudo curl | sh`. Git Bash and Windows cmd must not invoke Termux `pkg`.

**This requirement:** there is no in-tool sudo wrap on that class; GitLab operator verbs stay unused.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Fail closed; never probe random sudo.  
- **Intentional:** Closed argv table from disk study.  
- **Anti-fragile:** Root check happens even if sudo is a no-op under uid 0.  
- **Over-protect:** Do not widen argv because “we are already root.”

## 4. Protection Rule (Sacred)

**MUST NOT:**

1. Guess dest or argv.  
2. Treat harness `/etc/{{username}}/{{service}}` as this product’s wrap dest.  
3. Mark sibling verbs this CLI does not invoke as **This wrap? = yes**.  
4. Keep wrap bodies only on the coding-style requirement.  
5. Enable these wraps on Termux / Git Bash / Windows cmd.

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-GLN-07** | `tests/test_domain.sh` | have |
| **TP-GLN-08** | `tests/test_domain.sh` | have |
| **TP-GLN-12** | `tests/test_domain.sh` | have |
| **TP-GLN-13** | `tests/test_domain.sh` | have |

**Map:** `reviews/test-plan.md`.

## 5. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-domain-gitlab-cli.md` | Host setup + dedicated-account sudoers |
| `docs/requirements/requirement-shell-script-coding.md` | Coding-style pointer |
| `./gitlab-cli` | Implementation under test |

**Last Updated**: 2026-09-06  
**Owner**: gitlab-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
