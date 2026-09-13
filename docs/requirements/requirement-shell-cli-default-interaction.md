**file**: docs/requirements/requirement-shell-cli-default-interaction.md
**Status**: Active (Version 1.0.0)
**Area**: shell
**Key**: `requirement-shell-cli-default-interaction`
**id**: RQ-SHELL-CLI-DEFAULT-INTERACTION
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for gitlab-cli’s **TTY numbered list of live work commands**. The product **claims** that list. Look **MUST** be default CLI main menu style: header **gitlab-cli**(*version*) then `command: what it does` with gray italic descriptions on a TTY.

Empty argv is owned by `requirement-shell-cli-zero-arguments`: interactive empty argv is **this list**; off-TTY empty argv stays Type O install-ensure. `menu` / `main` are the same handler.

### 1.1 Human-facing

**In one sentence:** On a real terminal, type `gitlab-cli` with no arguments (or `gitlab-cli menu`) to get a numbered list of live GitLab work commands; a wrong number shows the list again; a script still installs or shows help and never waits.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Open the numbered list, pick a number or a command name | `gitlab-cli` then `1` or `list-users` |
| Automation / pipes | The list does not appear; empty argv installs this program | `curl … \| sh` |
| Not this file | Off-TTY empty argv stays install-ensure | `requirement-shell-cli-zero-arguments` |

| Includes | Excludes |
|----------|----------|
| Numbered 1…4 live work commands; last extra row Exit **9**; TTY empty argv; `menu` / `main`; invalid choice retries this layer | `help` as a row; install / uninstall / setup / version / about; `menu` as a choice; hanging in CI |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./gitlab-cli` | ship unit | live numbered list |
| `gitlab-cli` (no args, real terminal) | command | numbered list |
| `gitlab-cli` (no args, script) | command | install-ensure |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Want the numbered list | On a real terminal, empty argv **is** the list. `menu` / `main` are the same handler. `--json` does not hide the list on a TTY for `menu`. In a pipe, empty argv still installs. | `gitlab-cli` |
| Type a wrong number | The program says that number is not on this list and **prints the list again**. It does not exit. | `3` then `1` |
| Leave the list | Exit is **9** (four command rows). | `9` |

## Under command line for normal user only

On Termux, Git Bash, or Windows cmd, the numbered list **MUST** still omit install/setup. Host mutate chosen from the list **MUST** fail closed if the class cannot elevate.

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Claim and case (mandatory)

| Field | Value |
|-------|--------|
| **Claims a default function** | **yes** |
| **Zero-argument requirement present** | **yes** — `requirement-shell-cli-zero-arguments` (TTY empty argv **defers here**; off-TTY Type O) |
| **Online-installable** | **yes** |
| **Case** | **1 overlay** (TTY empty argv = this list; non-interactive empty argv stays Type O). `menu` / `main` also routed |

1. Empty argv **MUST** follow `requirement-shell-cli-zero-arguments`.
2. The numbered list **MUST** also be routed-verb **`menu`**. **`main` MUST** be the same handler.
3. **MUST NOT** draw the list off-TTY.
4. **MUST NOT** list `menu` / `main` as a numbered choice.
5. Choice **MUST** be current-shell `prompt_ask` then `PROMPT_ASK_VALUE`. **MUST NOT** `_choice=$(prompt_ask …)`.
6. Look **MUST** use `util_app_ident` + `out_menu_choice`.
7. An **invalid choice** (unused number such as `3`, unknown name, empty line) **MUST** `out_error`, reprint **this** layer, and re-prompt. **MUST NOT** `out_die` / process exit. **MUST NOT** treat that pick as unknown argv.

### 2.2 `menu` / `main` mode check

| Invocation | `--json` | MUST | MUST NOT |
|------------|----------|------|----------|
| Interactive (`TTY=1`) `gitlab-cli menu` | **Ignore** | Show the numbered list; read a number or a command name | Treat `--json` as JSON help; hang |
| Non-interactive (`TTY=0`) `gitlab-cli menu` | **Follow** | **Help**: human when `JSON=0`; JSON help when `JSON=1` | Draw the list; hang |

`--json` with **no command** is empty argv: JSON help (TTY and off-TTY) — not this list.

### 2.3 Numbered list (sacred)

**Normative numbered list (labels = human-readable):**

```text
1. list-users: List GitLab users
2. reset-password: Reset a GitLab user password (numbered list first)
3. status: Show gitlab-ctl status
4. remove-lpu: Remove gitlab-adm (confirm or --force)
9. Exit
```

**N** = **4**. **Exit** = **9**.

**MUST NOT** list: `help`; `install` / `setup`; self-managed; `version` / `about`; `menu` / `main` itself.

### 2.4 Implementation Notes (this project)

| Item | Value for gitlab-cli |
|------|---------------------|
| **Product / binary** | `gitlab-cli` |
| **Claimed** | yes |
| **Case** | **1 overlay** (TTY empty argv = list; pipe = Type O) |
| **Handler** | `app_main_menu` |
| **Ship-unit status** | **Implemented** |
| **N** | **4** |
| **Exit** | **9** |
| **Prompt helper** | `prompt_ask` then `PROMPT_ASK_VALUE` |

**Complete invocation samples:**

```text
gitlab-cli
gitlab-cli menu
gitlab-cli main
gitlab-cli menu --json
```

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution**: Scripts never hang on the list; invalid choice does not kill the process.
- **Intentional**: Four operational rows only; Exit 9.
- **Anti-fragile**: Off-TTY empty argv still installs.
- **Over-protect**: Exclusions and invalid-choice retry are sacred.

## 4. Protection Rule (Sacred)

**Future AI assistants or maintainers MUST NOT**:

1. Invent menu labels.
2. Put install / setup / version / about / help / menu itself on the list.
3. `out_die` on an invalid TTY menu choice.
4. Capture the choice with `$()` of `prompt_ask`.
5. Steal Type O **non-interactive** empty argv onto this list.
6. Draw the list for TTY `gitlab-cli --json` (no command).

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-16** | `tests/test_cli.sh` | have |
| **TP-CLI-17** | `tests/test_cli.sh` | have |
| **TP-CLI-19** | `tests/test_cli.sh` | have |

**Map:** `reviews/test-plan.md`.

## 5. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-cli-zero-arguments.md` | Empty argv owner |
| `docs/requirements/requirement-shell-cli-interface.md` | Dual mention of `menu` / `main` |
| `docs/requirements/requirement-domain-gitlab-cli.md` | Domain verbs on the list |
| `./gitlab-cli` | Implementation |

**Last Updated**: 2026-09-13
**Owner**: gitlab-cli project maintainers
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
