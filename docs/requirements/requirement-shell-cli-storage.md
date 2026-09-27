**file**: docs/requirements/requirement-shell-cli-storage.md  
**Status**: Active (Version 1.2.0)  
**Area**: shell  
**Key**: `requirement-shell-cli-storage`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **shell CLI storage** of gitlab-cli. **Storage** means **two** classes:

| Class | Role | Survives reboot |
|-------|------|-----------------|
| **Cache folder** | Volatile scratch / temps / install staging | No (shm/tmp) or maybe (home fallback) |
| **Persistence storage** | Type 0 durable per-user app data | Yes (under this login’s `$HOME`) |

It owns path **shapes**, central resolvers, `app_main` wire, and about diagnostics for both classes.

The preferred cache is **not** a ram-drive **project** tree (`/dev/shm/<project>` or `/dev/shm/<project>-<login>`). It lives under `/dev/shm/cache/` (Linux) or `/tmp/cache/` (Git Bash and Mac). The leaf is **per login and per process** so two logins never share one cache directory.

---

### 1.1 Human-facing

Scratch goes in a cache folder. Durable app data for this login goes under persistence storage. GitLab host files stay with the GitLab operator verbs. They are not this folder.

| You | Another role | Not this |
|-----|--------------|----------|
| Let the CLI pick cache + persistence | Root runs GitLab operator verbs (`list-users`, `reset-password`, `status`) | Putting scratch in `/tmp` with a guessed name; treating `~/.local/bin` as data |

**Includes:** cache resolver, persistence resolver, about fields. **Excludes:** GitLab host trees; install binary placement.

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Inspect storage | about shows Cache folder used, preferred, 1st fallback, 2nd fallback when that host has one, and Persistence storage. A skipped tier prints nothing | `gitlab-cli about` / `gitlab-cli --json about` |

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Two storage classes (mandatory split)

Volatile leaf (shared parents `/dev/shm` and `/tmp`): `cache-${APP_NAME}-${login}-$$`.  
Home leaf (already per login): `cache-${APP_NAME}-$$`.  
`$$` is **this process id**. `${login}` is `id -un` as one path segment. **MUST NOT** hardcode either.

| Host | Preferred | 1st fallback | 2nd fallback |
|------|-----------|--------------|--------------|
| Linux (and Termux, and any host that is not Git Bash or Mac) | `/dev/shm/cache/cache-${APP_NAME}-${login}-$$` | `/tmp/cache/cache-${APP_NAME}-${login}-$$` | `${HOME}/.cache/cache-${APP_NAME}-$$` |
| Git Bash (`MSYSTEM`, or `uname -s` `MINGW*` / `MSYS*`) | `/tmp/cache/cache-${APP_NAME}-${login}-$$` | `${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$` | none |
| Mac (`uname -s` `Darwin`) | `/tmp/cache/cache-${APP_NAME}-${login}-$$` | `${HOME}/Library/Caches/cache-${APP_NAME}-$$` | `${HOME}/cache/cache-${APP_NAME}-$$` |

| Class | Helper |
|-------|--------|
| Cache folder (preferred) | `util_preferred_cache_dir` |
| Cache folder (1st fallback) | `util_fallback_cache_dir` |
| Cache folder (2nd fallback) | `util_fallback2_cache_dir` (empty on Git Bash) |
| Persistence storage | `util_persistent_storage_dir` → `${HOME}/.local/${APP_NAME}` |

Live chosen **cache** root: `util_resolve_storage` (stdout).  
Live **persistence** root: `util_resolve_persistent_storage` (stdout; create-before-return).

On Termux/Android, the chosen cache root (including `/tmp` and `/dev/shm`) **MAY** be **`noexec`**. Termux uses the **Linux** chain. Cache remains scratch **only**. **MUST NOT** exec a downloaded binary that lives only in the cache root. Install **MUST** place the program under `USER_BIN` or `GLOBAL_BIN` before the operator runs it.

**Silent fallback.** Choosing a later tier **MUST NOT** print a warning or an error. **MUST NOT** say that a fallback happened. An error is allowed only when **every** tier for this host failed to be created.

**MUST NOT** mix these with:

| Forbidden as this product’s storage | Why |
|-------------------------------------|-----|
| `${HOME}/.local/bin` / `USER_BIN` | Install binary dir |
| A Type 1 `/var/…` deposit | Not this CLI’s persistence |
| `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` | Looks like a ram-drive project folder |
| `${HOME}/.local/share/${APP_NAME}` | Not this product’s persistence shape |
| `XDG_CACHE_HOME` or a caller `STORAGE_DIR` override as a cache tier | The chain above is the whole cache resolve |

### 2.2 Single cache resolver SSOT

1. **MUST** keep **one** authoritative cache-resolve helper: **`util_resolve_storage`**.  
2. New code that needs a product scratch/cache **root** **MUST** call `util_resolve_storage` (or `mktemp` under a path it returned).  
3. Resolver **MUST** print the chosen directory path on **stdout** for `$(util_resolve_storage)` capture.  
4. User-visible failure about cache **MUST** use Output SSOT.

Preferred, 1st fallback, and 2nd fallback **path shapes** **MUST** be `util_preferred_cache_dir`, `util_fallback_cache_dir`, and `util_fallback2_cache_dir`.

### 2.3 Live cache resolve priority

Walk this host’s chain in order. First directory that can be created **and** is writable wins. The chain is the table in §2.1. **MUST NOT** replace that chain with one shared `cache-${APP_NAME}` leaf or with `XDG_CACHE_HOME`.

**Parent:** for `/dev/shm/cache` and `/tmp/cache` the resolver **MUST** create that parent (prefer mode **1777** when creating) so each login can add its own `cache-${APP_NAME}-${login}-$$` leaf. The **leaf** **MUST** be mode **0700**.

**Create before return:** for the **chosen** leaf, the resolver **MUST** create it, confirm it is **writable**, then print the path. If create/write fails → try the next tier **with no message**. If none work → **MUST** fail closed. **MUST NOT** return a path without creating it.

**MUST NOT** use these as cache:

| Forbidden cache path | Why |
|----------------------|-----|
| `/dev/shm/${APP_NAME}` | Looks like a ram-drive project folder |
| `/dev/shm/${APP_NAME}-${USERNAME}` | Same confusion. Login belongs in the leaf **under** `cache/`, as `cache-${APP_NAME}-${login}-$$` |
| `/dev/shm` or `/tmp` as a dump | No app-named cache leaf |
| Persistence storage | Durable data is not scratch |

### 2.4 Cache isolation

1. Cache leaves **MUST** include **`cache-${APP_NAME}`** (app identity).  
2. Volatile leaves (`/dev/shm/cache` and `/tmp/cache`) **MUST** be `cache-${APP_NAME}-${login}-$$`. Home leaves **MUST** be `cache-${APP_NAME}-$$` (no login segment). Isolation is the login segment plus this process id, not one shared directory that the second login falls out of.  
3. **MUST NOT** use a single shared world-writable directory for all logins or all apps.  
4. Live product **MUST** export `TMPDIR=${EFFECTIVE_STORAGE_DIR}` so `mktemp` inherits the isolated **cache** root.  
5. New scratch files **MUST** be created via **`util_mktemp`** (or `mktemp` under a path `util_resolve_storage` returned).  
6. The **cache directory** name includes `$$` (this process). Scratch **files** inside it **MUST NOT** use a predictable `$$` file name (forbidden: `/tmp/${APP_NAME}.$$`, `${EFFECTIVE_STORAGE_DIR}/${APP_NAME}.$$`).

**Complete `util_mktemp` sample:**

```sh
util_mktemp() {
    : "${APP_NAME:=gitlab-cli}"
    : "${EFFECTIVE_STORAGE_DIR:=}"
    _suffix="${1:-tmp}"
    case "${_suffix}" in
        *\$\$*) out_die "util_mktemp: refuse predictable \$\$ name template" ;;
    esac
    if [ -z "${EFFECTIVE_STORAGE_DIR}" ]; then
        EFFECTIVE_STORAGE_DIR=$(util_resolve_storage)
        export EFFECTIVE_STORAGE_DIR
    fi
    mktemp "${EFFECTIVE_STORAGE_DIR}/${APP_NAME}.${_suffix}.XXXXXX" \
        || mktemp
}
```

**Forbidden:**

```sh
# MUST NOT
tmp="/tmp/${APP_NAME}.$$"
tmp="${EFFECTIVE_STORAGE_DIR}/${APP_NAME}.$$"
```

### 2.5 Persistence storage

1. Persistence **MUST** be **`${HOME}/.local/${APP_NAME}`** (this login’s home + app name).  
2. Helper **`util_persistent_storage_dir`** **MUST** print that path. **`util_resolve_persistent_storage`** **MUST** `mkdir -p` it, confirm it is writable, then print it (fail closed).  
3. **MUST NOT** use `${HOME}/.local/bin` as persistence (that is `USER_BIN`).  
4. **MUST NOT** use a Type 1 `/var/…` tree as Type 0 persistence.  
5. **MUST NOT** store scratch/temps in persistence when a cache root is available.  
6. Persistence **MUST** be under the invoking login’s `$HOME` (per-user). **MUST** include `${APP_NAME}`.  
7. GitLab host files (`gitlab-ctl`, `gitlab-rails`, `gitlab-adm`) **MUST** stay on `requirement-domain-gitlab-cli`. **MUST NOT** be relocated into `${HOME}/.local/${APP_NAME}`.

### 2.6 Wire and diagnostics

| Surface | Requirement |
|---------|-------------|
| `app_main` | Resolve once early: `EFFECTIVE_STORAGE_DIR=$(util_resolve_storage)`; `PERSISTENT_STORAGE_DIR=$(util_resolve_persistent_storage)`; export `EFFECTIVE_STORAGE_DIR`, `STORAGE_DIR` (1st fallback path), `PERSISTENT_STORAGE_DIR`, `TMPDIR` (`TMPDIR` = cache root) |
| `app_about` human | **MUST** print **`Cache folder used:`** then the live directory; **`Cache folder (preferred):`** then this host’s preferred path; **`Cache folder (1st fallback):`** then the 1st fallback; **`Cache folder (2nd fallback):`** only when this host has a 2nd fallback; **`Persistence storage:`** then `${HOME}/.local/${APP_NAME}`. Linux sample below. **MUST NOT** label cache lines **Storage (effective)** or **Storage (fallback)**. **MUST NOT** warn or error when the used directory is a fallback |
| `app_about` JSON | **MUST** include `cache_used`, `cache_preferred`, `cache_fallback` (1st), `cache_fallback_2` (2nd, empty string when the host has none), `persistence_storage`, and the live chosen cache root as `effective_storage` (same value as `cache_used`; `storage_dir` = 1st fallback). **MUST NOT** include `CHECKSUM` |

Linux `about` lines (placeholders, not a fixed process id). `Cache folder used` is the tier that was created:

```
[INFO] Cache folder used: /dev/shm/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (preferred): /dev/shm/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (1st fallback): /tmp/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (2nd fallback): ${HOME}/.cache/cache-${APP_NAME}-$$
[INFO] Persistence storage: ${HOME}/.local/${APP_NAME}
```

Git Bash omits the 2nd fallback line. Mac prints preferred under `/tmp/cache/`, 1st fallback under `${HOME}/Library/Caches/`, and 2nd fallback under `${HOME}/cache/`.

### 2.7 Implementation Notes (this project)

| Item | Live value |
|------|------------|
| **Product / binary** | `gitlab-cli` |
| **Cache resolver** | `util_resolve_storage` in `./gitlab-cli` |
| **Linux preferred** | `/dev/shm/cache/cache-${APP_NAME}-${login}-$$` |
| **Linux 1st / 2nd** | `/tmp/cache/cache-${APP_NAME}-${login}-$$` then `${HOME}/.cache/cache-${APP_NAME}-$$` |
| **Git Bash** | `/tmp/cache/cache-${APP_NAME}-${login}-$$` then `${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$` |
| **Mac** | `/tmp/cache/cache-${APP_NAME}-${login}-$$` then `${HOME}/Library/Caches/cache-${APP_NAME}-$$` then `${HOME}/cache/cache-${APP_NAME}-$$` |
| **Persistence** | `${HOME}/.local/gitlab-cli` |
| **Persistence resolver** | `util_resolve_persistent_storage` |
| **Scratch files** | `util_mktemp` (install staging, companion digest, user-list temp) |
| **Test-purpose host** | `GITLAB_CLI_CACHE_HOST=linux\|gitbash\|mac` selects the chain without changing the real host |
| **Test-purpose skip** | `GITLAB_CLI_CACHE_SKIP=preferred` skips tier 1 with no message |
| **Call sites** | `app_main`, `app_about` |
| **Not used for** | GitLab host files; install `~/.local/bin`; ram-drive project dests |

### 2.8 Why This Requirement Exists (CIAO)

- **Caution:** Multi-user isolation without looking like a project tree on tmpfs; durable Type 0 data is not mixed with bins.  
- **Intentional:** Storage = cache folder **and** persistence storage; about says both.  
- **Anti-fragile:** Missing `/dev/shm` still works, and the miss is silent.  
- **Principle 11 – Temps:** `TMPDIR` from the cache root; scratch names are `mktemp`, not `$$` files.

---

## Under command line for normal user only

When gitlab-cli runs on Termux, Git Bash, Windows cmd, or the same class (this login only — no root, no dedicated system account):

| MUST | MUST NOT |
|------|----------|
| Keep **normal user privilege** only for self-management | Enable **admin privilege** (`sudo`, write `/etc`) for install of this CLI |
| Treat admin-privilege and dedicated-account work as **unused** on that class | Wrap `apt` / `dnf` / `yum`; `useradd`; recommend `sudo curl \| sh` |
| Termux: cache may be `noexec`; scratch only | Exec a binary that lives only in the cache folder |
| Git Bash and Windows cmd: same ceiling | Invoke Termux `pkg` because those hosts were detected |

Detect: Termux — `uname` contains Android, or `PREFIX` / `TERMUX_VERSION` is set. Git Bash — `MSYSTEM` or `uname -s` is MINGW*/MSYS*. Windows cmd — `OS=Windows_NT` after excluding Git Bash, Cygwin, and WSL.

**This requirement:** cache and persistence stay under this login. Do not resolve scratch into `/etc`.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- Volatile cache first, user cache last for scratch.  
- Persistence is under `$HOME/.local/${APP_NAME}`, not under `bin` or `/var`.  
- Isolation before convenience.  
- Create fail-closed only when every tier failed. A skipped tier is silent.  
- Cache path family is distinct from ram-drive **project** folders.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Restore `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` as the preferred cache.  
2. Label about cache lines **Storage (effective)** / **Storage (fallback)**. The labels are **Cache folder used**, **Cache folder (preferred)**, **Cache folder (1st fallback)**, **Cache folder (2nd fallback)** when that host has one.  
3. Drop persistence storage from this requirement or from `about`.  
4. Use `${HOME}/.local/bin` or a Type 1 `/var/…` tree as Type 0 persistence.  
5. Replace the cache fallback chain with a shared world-writable dump, or with one `cache-${APP_NAME}` leaf shared by every login.  
6. Scatter hard-coded `/tmp/gitlab-cli` roots outside the cache resolver.  
7. Leave the resolvers dead with no call sites while claiming storage is product law.  
8. Echo a tier path without creating it.  
9. Use predictable `$$` scratch **file** names instead of `util_mktemp` / `mktemp` XXXXXX. The cache **directory** itself includes `$$`.  
10. Warn or error only because a higher cache tier was skipped.  
11. Drop `${login}` or `$$` from a volatile cache leaf, or put the login back on `/dev/shm/${APP_NAME}-${login}` outside `cache/`.  
12. Exec a downloaded binary from the cache folder, `/tmp`, or `/dev/shm` when that mount is `noexec`.  
13. Strip the **Under command line for normal user only** section, or enable admin privilege / a dedicated system user on Termux / Git Bash / Windows cmd for this CLI’s self-management.  
14. Honor `STORAGE_DIR` or `XDG_CACHE_HOME` as a cache tier that replaces the host chain.

**Violating this rule is a critical cache isolation / honesty regression.**

---

## 5. Acceptance criteria

| ID | Criterion |
|----|-----------|
| AC-1 | Exactly one authoritative cache resolver creates and returns the cache root |
| AC-2 | Linux preferred leaf is `/dev/shm/cache/cache-${APP_NAME}-${login}-$$` when that directory is usable. Git Bash and Mac preferred leaf is `/tmp/cache/cache-${APP_NAME}-${login}-$$` |
| AC-3 | `app_main` sets `EFFECTIVE_STORAGE_DIR` / `TMPDIR` / `PERSISTENT_STORAGE_DIR` early |
| AC-4 | `about` human prints Cache folder used, preferred, 1st fallback, 2nd fallback when present, and Persistence storage; JSON has `cache_used` / `cache_preferred` / `cache_fallback` / `cache_fallback_2` / `persistence_storage` |
| AC-5 | Scratch files use `util_mktemp` / `mktemp` XXXXXX; the cache directory name may include `$$`; scratch file names must not |
| AC-6 | Live cache path is not `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` |
| AC-7 | Persistence path is `${HOME}/.local/${APP_NAME}` and the directory exists after resolve |
| AC-8 | Skipping a cache tier prints no warning and no error. Git Bash has no 2nd fallback. Mac 2nd fallback is `${HOME}/cache/cache-${APP_NAME}-$$` |

---

## 6. Related requirements (peer keys only)

| Key | Relationship |
|-----|--------------|
| `requirement-shell-cli-interface` | About command surface |
| `requirement-shell-output-requirements` | about JSON via `out_json`; cache helpers are class B returns |
| `requirement-shell-modular-function-design` | `util_*` ownership |
| `requirement-shell-self-management` | about lifecycle; install bin is not persistence |
| `requirement-domain-gitlab-cli` | GitLab host files — not this folder |
| `docs/requirements/index.md` | Registry |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-04** | `tests/test_cli.sh` | **have** — about JSON `cache_used` / `cache_preferred` / `cache_fallback` / `cache_fallback_2` / `persistence_storage` / `effective_storage`; human Cache folder used, preferred, 1st, 2nd, Persistence storage; no CHECKSUM |
| **TP-CLI-05** | same | **have** — Linux preferred `/dev/shm/cache/cache-${APP_NAME}-${login}-$$`; 1st `/tmp/cache/...`; 2nd `${HOME}/.cache/cache-${APP_NAME}-$$`; Git Bash and Mac chains; silent skip of preferred; leaf mode 0700; persistence `${HOME}/.local/${APP_NAME}`; live dir exists; not `/dev/shm/${APP_NAME}-${login}` |

**Matrix:** `reviews/requirement-test-matrix.md`  
**Map:** `reviews/test-plan.md`

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-09-06 | Active 1.1.0 | Cache folder and persistence folder; preferred `/dev/shm/${APP_NAME}-${USERNAME}` |
| 2026-09-27 | Active 1.2.0 | Per-login per-process cache leaves. Linux shm → tmp → `${HOME}/.cache`. Git Bash tmp → AppData Local Temp. Mac tmp → Library/Caches → `${HOME}/cache`. Silent tier miss. `about` prints used / preferred / 1st / 2nd |

---

**Last Updated**: 2026-09-27  
**Owner**: gitlab-cli project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; **CIAO** (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
