# =============================================================================
# tests/test_domain.sh — gitlab-cli domain surface (RQ-DOMAIN-GITLAB-CLI)
# =============================================================================
# Host-mutating GitLab rails/ctl need root + Omnibus. This suite proves
# dispatch, help, about domain rows, empty-argv ≠ GitLab mutate, and
# non-root fail-closed for list-users / reset-password / status / setup.
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

run_test_domain() {
    t_header "Domain surface (TP-GITLAB-CLI-*)"

    require_cmd sh

    # --- TP-GITLAB-CLI-01: help lists GitLab verbs; omits nginx ---
    _out=$(sh "${SCRIPT}" help 2>/dev/null)
    _ec=$?
    assert_eq "TP-GITLAB-CLI-01 help exit 0" 0 "$_ec"
    assert_contains "TP-GITLAB-CLI-01 help lists list-users" "$_out" "list-users"
    assert_contains "TP-GITLAB-CLI-01 help lists reset-password" "$_out" "reset-password"
    assert_contains "TP-GITLAB-CLI-01 help lists status" "$_out" "status"
    assert_contains "TP-GITLAB-CLI-01 help lists setup" "$_out" "setup"
    assert_contains "TP-GITLAB-CLI-01 help lists remove-lpu" "$_out" "remove-lpu"
    assert_contains "TP-GITLAB-CLI-01 help still lists install" "$_out" "install"
    assert_contains "TP-GITLAB-CLI-01 help still lists self-update" "$_out" "self-update"
    assert_not_contains "TP-GITLAB-CLI-01 help omits nginx-conf" "$_out" "nginx-conf"
    assert_not_contains "TP-GITLAB-CLI-01 help omits --no-cloudflare" "$_out" "--no-cloudflare"
    assert_not_contains "TP-GITLAB-CLI-01 help omits domains command row" "$_out" "Show saved domains"
    assert_not_contains "TP-GITLAB-CLI-01 help omits Java" "$_out" "Java"

    # --- TP-GITLAB-CLI-02: help --json notes GitLab verbs ---
    _out=$(sh "${SCRIPT}" --json help 2>/dev/null)
    _ec=$?
    assert_eq "TP-GITLAB-CLI-02 help --json exit 0" 0 "$_ec"
    assert_contains "TP-GITLAB-CLI-02 help --json success" "$_out" '"type":"success"'
    assert_contains "TP-GITLAB-CLI-02 help --json notes list-users" "$_out" "list-users"
    assert_contains "TP-GITLAB-CLI-02 help --json notes reset-password" "$_out" "reset-password"

    # --- TP-GITLAB-CLI-03: about JSON domain fields ---
    _out=$(sh "${SCRIPT}" --json about 2>/dev/null)
    _ec=$?
    assert_eq "TP-GITLAB-CLI-03 about --json exit 0" 0 "$_ec"
    assert_contains "TP-GITLAB-CLI-03 about type" "$_out" '"type":"about"'
    assert_contains "TP-GITLAB-CLI-03 about gitlab_ctl" "$_out" '"gitlab_ctl"'
    assert_contains "TP-GITLAB-CLI-03 about gitlab_rails" "$_out" '"gitlab_rails"'
    assert_contains "TP-GITLAB-CLI-03 about gitlab_adm" "$_out" '"gitlab_adm"'
    assert_contains "TP-GITLAB-CLI-03 about domain product" "$_out" '"domain":"gitlab-cli"'
    assert_not_contains "TP-GITLAB-CLI-03 about omits domains_file" "$_out" '"domains_file"'

    # --- TP-GITLAB-CLI-04: empty argv off-TTY is Type O, not GitLab mutate ---
    ci_isolated_env
    _errf="${CI_HOME}/empty-arg-err.txt"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SCRIPT_URL="http://127.0.0.1:1/gitlab-cli-unreachable" \
        sh "${SCRIPT}" </dev/null 2>"${_errf}"
    )
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    _all="${_out}${_err}"
    if [ "$_ec" -ne 0 ]; then
        t_pass "TP-GITLAB-CLI-04 empty argv failed install exits non-zero (Type O)"
    else
        t_fail "TP-GITLAB-CLI-04 empty argv expected non-zero without channel, got 0"
    fi
    assert_not_contains "TP-GITLAB-CLI-04 empty argv must not start GitLab install text" "$_all" "Installing GitLab"
    assert_not_contains "TP-GITLAB-CLI-04 empty argv must not list users" "$_all" "gitlab-rails runner"
    assert_file_missing "TP-GITLAB-CLI-04 empty argv left no binary" "${CI_USER_BIN}/gitlab-cli"
    ci_cleanup_env

    # --- TP-GITLAB-CLI-05: list-users routed; non-root fail-closed ---
    _errf=$(mktemp)
    _out=$(sh "${SCRIPT}" list-users 2>"${_errf}")
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    rm -f "${_errf}"
    _all="${_out}${_err}"
    assert_eq "TP-GITLAB-CLI-05 list-users non-root exit 1" 1 "$_ec"
    assert_not_contains "TP-GITLAB-CLI-05 list-users not unknown" "$_all" "Unknown command"
    assert_contains "TP-GITLAB-CLI-05 list-users root required" "$_all" "root"
    assert_contains "TP-GITLAB-CLI-05 list-users Next:" "$_all" "Next:"

    # --- TP-GITLAB-CLI-06: reset-password routed; non-root fail-closed ---
    _errf=$(mktemp)
    _out=$(sh "${SCRIPT}" reset-password 2>"${_errf}")
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    rm -f "${_errf}"
    _all="${_out}${_err}"
    assert_eq "TP-GITLAB-CLI-06 reset-password non-root exit 1" 1 "$_ec"
    assert_not_contains "TP-GITLAB-CLI-06 reset-password not unknown" "$_all" "Unknown command"
    assert_contains "TP-GITLAB-CLI-06 reset-password root required" "$_all" "root"

    # --- TP-GITLAB-CLI-07: status without root fails closed ---
    _errf=$(mktemp)
    _out=$(sh "${SCRIPT}" status 2>"${_errf}")
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    rm -f "${_errf}"
    _all="${_out}${_err}"
    assert_eq "TP-GITLAB-CLI-07 status non-root exit 1" 1 "$_ec"
    assert_not_contains "TP-GITLAB-CLI-07 status not unknown" "$_all" "Unknown command"
    assert_contains "TP-GITLAB-CLI-07 status root required" "$_all" "root"

    # --- TP-GITLAB-CLI-08: setup without root fails closed ---
    _errf=$(mktemp)
    _out=$(sh "${SCRIPT}" setup </dev/null 2>"${_errf}")
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    rm -f "${_errf}"
    _all="${_out}${_err}"
    assert_eq "TP-GITLAB-CLI-08 setup non-root exit 1" 1 "$_ec"
    assert_not_contains "TP-GITLAB-CLI-08 setup not unknown" "$_all" "Unknown command"
    assert_contains "TP-GITLAB-CLI-08 setup root required" "$_all" "root"

    # --- TP-GITLAB-CLI-09: remove-lpu without root fails closed ---
    _errf=$(mktemp)
    _out=$(sh "${SCRIPT}" remove-lpu 2>"${_errf}")
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    rm -f "${_errf}"
    _all="${_out}${_err}"
    assert_eq "TP-GITLAB-CLI-09 remove-lpu non-root exit 1" 1 "$_ec"
    assert_not_contains "TP-GITLAB-CLI-09 remove-lpu not unknown" "$_all" "Unknown command"
    assert_contains "TP-GITLAB-CLI-09 remove-lpu root required" "$_all" "root"

    # --- TP-GITLAB-CLI-10: nginx verbs are unknown ---
    _err=$(sh "${SCRIPT}" nginx-conf 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-GITLAB-CLI-10 nginx-conf exit 1" 1 "$_ec"
    assert_contains "TP-GITLAB-CLI-10 nginx-conf unknown" "$_err" "Unknown command"

    _err=$(sh "${SCRIPT}" domains 2>&1 >/dev/null)
    _ec=$?
    assert_eq "TP-GITLAB-CLI-10 domains exit 1" 1 "$_ec"
    assert_contains "TP-GITLAB-CLI-10 domains unknown" "$_err" "Unknown command"
}
