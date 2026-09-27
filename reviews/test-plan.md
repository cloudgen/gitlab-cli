# Test plan — gitlab-cli

Maps **portable TP families** (proof molds) and product domain cases to product-root `tests/`.

| Field | Value |
|-------|--------|
| **Product** | gitlab-cli |
| **Ship unit** | `./gitlab-cli` · `VERSION=1.0.1` |
| **Companion** | `./gitlab-cli.sha256` |
| **Suite entry** | `./tests/run.sh` |
| **Live law** | **14** Active REQs — `docs/requirements/index.md` |
| **Bootstrap origin** | selfmanaged Type 0; stripped from gitlab-nginx |
| **Last update** | 2026-09-27 (1.0.1 cache folder) |

Status: **have** = automated · **todo** = needed · **n/a** = not applicable · **optional** = gated (root/host)

---

## Proof molds (cite by PM-ID)

| Family | Proof mold-ID | Suite file(s) | Primary product law |
|--------|---------------|---------------|---------------------|
| **TP-CLI** | `PM-SHELL-CLI-TEST-PLAN` | `tests/test_cli.sh` | RQ-SHELL-CLI-INTERFACE · RQ-SHELL-CLI-DEFAULT-INTERACTION · RQ-SHELL-CLI-STORAGE |
| **TP-LC** | `PM-INSTALL-LIFECYCLE-TEST-PLAN` | `tests/test_install_lifecycle.sh` | RQ-SHELL-SELF-MANAGEMENT · RQ-SHELL-IDEMPOTENCY · RQ-SHELL-AUTOMATIC-CHECKSUM |
| **TP-CSUM** | `PM-CHECKSUM-TEST-PLAN` | CLI + lifecycle | RQ-SHELL-AUTOMATIC-CHECKSUM |
| **TP-GITLAB-CLI** | `PM-DOMAIN-TEST-PLAN` (domain subject) | `tests/test_domain.sh` | **RQ-DOMAIN-GITLAB-CLI** |
| Umbrella | `PM-SHELL-CLI-SUITE-TEST-PLAN` | `tests/run.sh` | full Type 0 + domain surface |

---

## Baseline result

| Date | Result | Notes |
|------|--------|-------|
| 2026-09-13 | **PASS=189 FAIL=0 SKIP=0** | 1.0.0 gitlab-cli strip + menu + list-users / reset-password |
| 2026-09-27 | **PASS=212 FAIL=0 SKIP=0** | 1.0.1 per-login per-process cache folder |

**How to re-baseline:** `cd` product root → `./tests/run.sh` → paste summary into this table when law/suite changes.

---

## TP-CLI — CLI surface

| TP-ID | Intent | Status | Evidence |
|-------|--------|--------|----------|
| TP-CLI-01 | Syntax + companion digest | **have** | `sh -n`; `gitlab-cli.sha256` |
| TP-CLI-02 | Version human + JSON | **have** | app/version fields |
| TP-CLI-03 | Help Type 0; no CHECKSUM | **have** | test_cli |
| TP-CLI-04 | About JSON cache_used / cache_preferred / cache_fallback / cache_fallback_2 / persistence_storage + human Cache folder used, preferred, 1st, 2nd + Persistence storage | **have** | test_cli |
| TP-CLI-05 | Linux preferred `/dev/shm/cache/cache-${APP_NAME}-${login}-$$`; Git Bash and Mac chains; silent skip of preferred; leaf mode 0700; persistence `${HOME}/.local/${APP_NAME}`; not a ram-drive project path | **have** | test_cli |
| TP-CLI-06 | Unknown command fail-closed | **have** | exit 1 + out_error |
| TP-CLI-07 | quiet / env -u HOME | **have** | test_cli |
| TP-CLI-08 | Zero-arg failed install non-zero | **have** | bad SCRIPT_URL + isolate |
| TP-CLI-09 | self-uninstall --json confirm_required | **have** | test_cli |
| TP-CLI-16 | no `$()` of prompt_* | **have** | grep ship unit |
| TP-CLI-17 | TTY menu header + gray italic; off-TTY menu is help | **have** | PTY + off-TTY |
| TP-CLI-19 | Invalid menu choice retries this layer | **have** | PTY feed `3` then `9` |

---

## TP-LC — Install lifecycle (local HTTP channel)

| TP-ID | Intent | Status | Evidence |
|-------|--------|--------|----------|
| TP-LC-01 | install --json to USER_BIN | **have** | local channel |
| TP-LC-02 | Idempotent re-install | **have** | already installed |
| TP-LC-03 | Zero-arg Type O when installed (off-TTY) | **have** | local + global path cases |
| TP-LC-04 | version-check schema | **have** | ver_check keys |
| TP-LC-05 | self-update already-latest | **have** | lifecycle |
| TP-LC-06 | Human companion transparency | **have** | PASS digest lines |
| TP-LC-07 | Uninstall refuse / force | **have** | lifecycle |
| TP-LC-08 | CHECKSUM pin match/mismatch | **have** | lifecycle |
| TP-LC-09 | Downgrade blocked / --force | **have** | lifecycle |

---

## TP-GITLAB-CLI — Domain surface (`RQ-DOMAIN-GITLAB-CLI`)

| TP-ID | Intent | Status | Evidence |
|-------|--------|--------|----------|
| TP-GITLAB-CLI-01 | Help lists GitLab verbs; omits nginx | **have** | test_domain |
| TP-GITLAB-CLI-02 | Help --json notes list-users / reset-password | **have** | test_domain |
| TP-GITLAB-CLI-03 | About JSON gitlab_ctl / gitlab_rails / gitlab_adm | **have** | test_domain |
| TP-GITLAB-CLI-04 | Empty argv off-TTY is Type O not GitLab mutate | **have** | test_domain |
| TP-GITLAB-CLI-05 | list-users non-root fail-closed | **have** | test_domain |
| TP-GITLAB-CLI-06 | reset-password non-root fail-closed | **have** | test_domain |
| TP-GITLAB-CLI-07 | status non-root fail-closed | **have** | test_domain |
| TP-GITLAB-CLI-08 | setup non-root fail-closed | **have** | test_domain |
| TP-GITLAB-CLI-09 | remove-lpu non-root fail-closed | **have** | test_domain |
| TP-GITLAB-CLI-10 | nginx-conf / domains unknown | **have** | test_domain |
