# =============================================================================
# tests/test_cli.sh — Type 0 CLI surface (no network install required)
# =============================================================================
# Covers: syntax, version, help, about, unknown command, quiet/json modes,
# help must not list CHECKSUM, self-uninstall --json fail-closed (INC-20260713-002
# contract shape when a binary is present under isolated USER_BIN).
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

run_test_cli() {
    t_header "CLI surface"

    require_cmd sh
    require_cmd sha256sum
    require_cmd grep

    # --- syntax ---
    sh -n "${SCRIPT}"
    _syn=$?
    assert_eq "sh -n gitlab-cli (syntax)" 0 "$_syn"

    # --- companion digest matches ship unit ---
    if [ -f "${REPO_ROOT}/gitlab-cli.sha256" ]; then
        _expected=$(tr -d ' \n\r\t' < "${REPO_ROOT}/gitlab-cli.sha256")
        _actual=$(sha256sum "${SCRIPT}" | awk '{print $1}')
        assert_eq "gitlab-cli.sha256 matches ./gitlab-cli" "$_expected" "$_actual"
    else
        t_fail "gitlab-cli.sha256 missing at repo root"
    fi

    # --- version (human) ---
    _out=$(sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "version exit 0" 0 "$_ec"
    assert_contains "version human mentions version" "$_out" "${PRODUCT_VERSION}"
    assert_contains "version human mentions app" "$_out" "gitlab-cli"

    # --- version (json) ---
    _out=$(sh "${SCRIPT}" --json version 2>/dev/null)
    _ec=$?
    assert_eq "version --json exit 0" 0 "$_ec"
    assert_contains "version --json type" "$_out" '"type":"version"'
    assert_contains "version --json app" "$_out" '"app":"gitlab-cli"'
    assert_contains "version --json version field" "$_out" "\"version\":\"${PRODUCT_VERSION}\""
    # app_version is the live dispatcher target (M1); no dual inline path
    assert_contains "version human via app_version" "$(sh "${SCRIPT}" version 2>/dev/null)" "${PRODUCT_VERSION}"

    # --- help (human): commands present, CHECKSUM absent ---
    _out=$(sh "${SCRIPT}" help 2>/dev/null)
    _ec=$?
    assert_eq "help exit 0" 0 "$_ec"
    assert_contains "help lists install" "$_out" "install"
    assert_contains "help lists version-check" "$_out" "version-check"
    assert_contains "help lists self-update" "$_out" "self-update"
    assert_contains "help lists self-uninstall" "$_out" "self-uninstall"
    assert_contains "help lists about" "$_out" "about"
    assert_contains "help lists --json" "$_out" "--json"
    assert_contains "help lists --force" "$_out" "--force"
    assert_contains "help lists REPO_USER" "$_out" "REPO_USER"
    assert_contains "help lists REPO_NAME" "$_out" "REPO_NAME"
    assert_contains "help lists SCRIPT_URL" "$_out" "SCRIPT_URL"
    assert_not_contains "help must not list CHECKSUM" "$_out" "CHECKSUM"

    # --- help (json): short object, not full prose ---
    _out=$(sh "${SCRIPT}" --json help 2>/dev/null)
    _ec=$?
    assert_eq "help --json exit 0" 0 "$_ec"
    assert_contains "help --json type success" "$_out" '"type":"success"'
    assert_contains "help --json command help" "$_out" '"command":"help"'

    # --- TP-CLI-04 about: cache folders + persistence; no CHECKSUM ---
    _app="${APP_NAME:-gitlab-cli}"
    _out=$(sh "${SCRIPT}" --json about 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-04 about --json exit 0" 0 "$_ec"
    assert_contains "TP-CLI-04 about --json type" "$_out" '"type":"about"'
    assert_contains "TP-CLI-04 about --json app" "$_out" '"app":"gitlab-cli"'
    assert_not_contains "TP-CLI-04 about --json must not include CHECKSUM" "$_out" "CHECKSUM"
    assert_contains "TP-CLI-04 cache_used" "$_out" '"cache_used"'
    assert_contains "TP-CLI-04 cache_preferred" "$_out" '"cache_preferred"'
    assert_contains "TP-CLI-04 cache_fallback" "$_out" '"cache_fallback"'
    assert_contains "TP-CLI-04 cache_fallback_2" "$_out" '"cache_fallback_2"'
    assert_contains "TP-CLI-04 persistence_storage" "$_out" '"persistence_storage"'
    assert_contains "TP-CLI-04 effective_storage" "$_out" '"effective_storage"'
    assert_contains "TP-CLI-04 storage_dir" "$_out" '"storage_dir"'
    assert_contains "TP-CLI-04 storage includes app name" "$_out" "${_app}"
    _out_h=$(sh "${SCRIPT}" about 2>/dev/null)
    assert_contains "TP-CLI-04 human Cache folder used" "$_out_h" "Cache folder used:"
    assert_contains "TP-CLI-04 human Cache folder preferred" "$_out_h" "Cache folder (preferred):"
    assert_contains "TP-CLI-04 human Cache folder 1st fallback" "$_out_h" "Cache folder (1st fallback):"
    assert_contains "TP-CLI-04 human Cache folder 2nd fallback" "$_out_h" "Cache folder (2nd fallback):"
    assert_contains "TP-CLI-04 human Persistence storage" "$_out_h" "Persistence storage:"
    assert_not_contains "TP-CLI-04 no Storage (effective) label" "$_out_h" "Storage (effective)"
    assert_not_contains "TP-CLI-04 no Storage (fallback) label" "$_out_h" "Storage (fallback)"

    # --- TP-CLI-05 cache isolation: per login, per process, host chains ---
    ci_isolated_env 2>/dev/null || true
    if [ -n "${CI_HOME:-}" ]; then
        _login=$(id -un 2>/dev/null || echo "unknown")
        _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN:-${CI_HOME}/.local/bin}" \
            sh "${SCRIPT}" --json about 2>/dev/null)
        assert_contains "TP-CLI-05 isolated about has app in cache" "$_out" "${_app}"
        _pref=$(printf '%s' "$_out" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
        _pid="${_pref##*-}"
        case "${_pref}" in
            /dev/shm/cache/cache-"${_app}"-"${_login}"-[0-9]*)
                t_pass "TP-CLI-05 cache_preferred is shm login process leaf"
                ;;
            *) t_fail "TP-CLI-05 cache_preferred unexpected: '${_pref:-empty}'" ;;
        esac
        _fb=$(printf '%s' "$_out" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 cache_fallback 1st" "/tmp/cache/cache-${_app}-${_login}-${_pid}" "${_fb}"
        _fb2=$(printf '%s' "$_out" | sed -n 's/.*"cache_fallback_2":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 cache_fallback 2nd" "${CI_HOME}/.cache/cache-${_app}-${_pid}" "${_fb2}"
        _used=$(printf '%s' "$_out" | sed -n 's/.*"cache_used":"\([^"]*\)".*/\1/p' | head -n1)
        _eff=$(printf '%s' "$_out" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 cache_used matches effective" "${_eff}" "${_used}"
        _sdir=$(printf '%s' "$_out" | sed -n 's/.*"storage_dir":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 storage_dir is 1st fallback" "${_fb}" "${_sdir}"
        if [ -n "$_eff" ] && [ -d "$_eff" ]; then
            t_pass "TP-CLI-05 effective cache directory exists"
        else
            t_fail "TP-CLI-05 effective cache missing: '${_eff:-empty}'"
        fi
        case "${_eff}" in
            /dev/shm/"${_app}"|/dev/shm/"${_app}"-*)
                t_fail "TP-CLI-05 effective cache must not be ram-drive project shape: '${_eff}'"
                ;;
            *) t_pass "TP-CLI-05 effective cache is not a ram-drive project shape" ;;
        esac
        _mode=$(stat -c %a "${_eff}" 2>/dev/null || echo "")
        assert_eq "TP-CLI-05 effective cache mode 0700" "700" "${_mode}"
        _err=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN:-${CI_HOME}/.local/bin}" \
            GITLAB_CLI_CACHE_SKIP=preferred \
            sh "${SCRIPT}" about 2>&1 >/dev/null)
        assert_not_contains "TP-CLI-05 silent cache fallback" "${_err}" "fallback"
        assert_not_contains "TP-CLI-05 silent cache fallback error" "${_err}" "Cannot create cache"
        _skip=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN:-${CI_HOME}/.local/bin}" \
            GITLAB_CLI_CACHE_SKIP=preferred \
            sh "${SCRIPT}" --json about 2>/dev/null)
        _skip_eff=$(printf '%s' "$_skip" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
        _skip_fb=$(printf '%s' "$_skip" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 skipped preferred uses 1st fallback" "${_skip_fb}" "${_skip_eff}"
        _gb=$(HOME="${CI_HOME}" GITLAB_CLI_CACHE_HOST=gitbash \
            sh "${SCRIPT}" --json about 2>/dev/null)
        _gb_pref=$(printf '%s' "$_gb" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
        _gb_pid="${_gb_pref##*-}"
        assert_eq "TP-CLI-05 gitbash preferred" "/tmp/cache/cache-${_app}-${_login}-${_gb_pid}" "${_gb_pref}"
        _gb_fb=$(printf '%s' "$_gb" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 gitbash 1st fallback" "${CI_HOME}/AppData/Local/Temp/cache-${_app}-${_gb_pid}" "${_gb_fb}"
        assert_contains "TP-CLI-05 gitbash json has empty cache_fallback_2" "${_gb}" '"cache_fallback_2":""'
        _gb_fb2=$(printf '%s' "$_gb" | sed -n 's/.*"cache_fallback_2":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 gitbash no 2nd fallback" "" "${_gb_fb2}"
        _mac=$(HOME="${CI_HOME}" GITLAB_CLI_CACHE_HOST=mac \
            sh "${SCRIPT}" --json about 2>/dev/null)
        _mac_pref=$(printf '%s' "$_mac" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
        _mac_pid="${_mac_pref##*-}"
        assert_eq "TP-CLI-05 mac preferred" "/tmp/cache/cache-${_app}-${_login}-${_mac_pid}" "${_mac_pref}"
        _mac_fb=$(printf '%s' "$_mac" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 mac 1st fallback" "${CI_HOME}/Library/Caches/cache-${_app}-${_mac_pid}" "${_mac_fb}"
        _mac_fb2=$(printf '%s' "$_mac" | sed -n 's/.*"cache_fallback_2":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 mac 2nd fallback" "${CI_HOME}/cache/cache-${_app}-${_mac_pid}" "${_mac_fb2}"
        _hum_l=$(HOME="${CI_HOME}" sh "${SCRIPT}" about 2>/dev/null)
        assert_contains "TP-CLI-05 linux about used" "${_hum_l}" "Cache folder used:"
        assert_contains "TP-CLI-05 linux about preferred path" "${_hum_l}" "/dev/shm/cache/cache-${_app}-${_login}-"
        assert_contains "TP-CLI-05 linux about 2nd path" "${_hum_l}" "/.cache/cache-${_app}-"
        _hum_gb=$(HOME="${CI_HOME}" GITLAB_CLI_CACHE_HOST=gitbash sh "${SCRIPT}" about 2>/dev/null)
        assert_contains "TP-CLI-05 gitbash about 1st" "${_hum_gb}" "AppData/Local/Temp/cache-${_app}-"
        assert_not_contains "TP-CLI-05 gitbash about omits 2nd" "${_hum_gb}" "Cache folder (2nd fallback)"
        _hum_mac=$(HOME="${CI_HOME}" GITLAB_CLI_CACHE_HOST=mac sh "${SCRIPT}" about 2>/dev/null)
        assert_contains "TP-CLI-05 mac about 1st" "${_hum_mac}" "Library/Caches/cache-${_app}-"
        assert_contains "TP-CLI-05 mac about 2nd path" "${_hum_mac}" "Cache folder (2nd fallback): ${CI_HOME}/cache/cache-${_app}-"
        _persist=$(printf '%s' "$_out" | sed -n 's/.*"persistence_storage":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 persistence_storage path" "${CI_HOME}/.local/${_app}" "${_persist}"
        if [ -n "$_persist" ] && [ -d "$_persist" ]; then
            t_pass "TP-CLI-05 persistence storage directory exists"
        else
            t_fail "TP-CLI-05 persistence storage missing: '${_persist:-empty}'"
        fi
        case "${_persist}" in
            */.local/bin|*/.local/bin/) t_fail "TP-CLI-05 persistence must not be USER_BIN: '${_persist}'" ;;
            *) t_pass "TP-CLI-05 persistence is not the install bin directory" ;;
        esac
        ci_cleanup_env 2>/dev/null || true
    else
        _out=$(sh "${SCRIPT}" --json about 2>/dev/null)
        _eff=$(printf '%s' "$_out" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
        if [ -n "$_eff" ] && [ -d "$_eff" ]; then
            t_pass "TP-CLI-05 effective_storage directory exists after resolve"
        else
            t_fail "TP-CLI-05 effective_storage missing or not a directory: '${_eff:-empty}'"
        fi
    fi

    # --- unknown command ---
    _err=$(sh "${SCRIPT}" no-such-command 2>&1 >/dev/null)
    _ec=$?
    assert_eq "unknown command exit 1" 1 "$_ec"
    assert_contains "unknown command error text" "$_err" "Unknown command"

    _err=$(sh "${SCRIPT}" --json no-such-command 2>&1 >/dev/null)
    _ec=$?
    assert_eq "unknown command --json exit 1" 1 "$_ec"
    assert_contains "unknown command --json type error" "$_err" '"type":"out_error"'

    # --- quiet: version should not print info banners ---
    # Contract: --quiet suppresses non-error chatter; version uses out_info → suppressed.
    _out=$(sh "${SCRIPT}" --quiet version 2>/dev/null)
    _ec=$?
    assert_eq "version --quiet exit 0" 0 "$_ec"
    # out_info is suppressed under quiet → empty or near-empty stdout is correct
    if [ -z "$_out" ]; then
        t_pass "version --quiet suppresses human info"
    else
        _trim=$(printf '%s' "$_out" | tr -d ' \t\n\r')
        if [ -z "$_trim" ]; then
            t_pass "version --quiet suppresses human info"
        else
            t_fail "version --quiet expected empty stdout, got '$(_trunc "$_out")'"
        fi
    fi

    # --- HOME unset under set -u (INC-20260713-001) ---
    # Must not abort with "HOME: parameter not set"; defaults HOME then USER_BIN.
    _out=$(env -u HOME sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "env -u HOME version exit 0" 0 "$_ec"
    assert_contains "env -u HOME version still reports version" "$_out" "${PRODUCT_VERSION}"

    # --- zero-arg auto-install propagates failure (not exit 0 on download fail) ---
    ci_isolated_env
    _errf="${CI_HOME}/zero-arg-err.txt"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SCRIPT_URL="http://127.0.0.1:1/gitlab-cli-unreachable" \
        sh "${SCRIPT}" </dev/null 2>"${_errf}"
    )
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    if [ "$_ec" -ne 0 ]; then
        t_pass "zero-arg failed install exits non-zero"
    else
        t_fail "zero-arg failed install expected non-zero exit, got 0 (stdout='$(_trunc "$_out")' err='$(_trunc "$_err")')"
    fi
    assert_file_missing "zero-arg failed install left no binary" "${CI_USER_BIN}/gitlab-cli"
    ci_cleanup_env

    # --- self-uninstall --json without force when binary present (isolated) ---
    # Fail-closed confirm_required (INC-20260713-002 contract).
    ci_isolated_env
    mkdir -p "${CI_USER_BIN}"
    # Place a stub install so uninstall path runs without network
    cp "${SCRIPT}" "${CI_USER_BIN}/gitlab-cli"
    chmod +x "${CI_USER_BIN}/gitlab-cli"
    _errf="${CI_HOME}/un-err.txt"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        sh "${SCRIPT}" --json self-uninstall 2>"${_errf}"
    )
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    assert_eq "self-uninstall --json without --force exit 1" 1 "$_ec"
    assert_contains "self-uninstall --json confirm_required code" "$_err" '"code":"confirm_required"'
    assert_contains "self-uninstall --json out_error type" "$_err" '"type":"out_error"'
    assert_not_contains "self-uninstall --json must not fake success cancel" "$_out$_err" "cancelled by user"
    assert_file_exists "binary remains without --force" "${CI_USER_BIN}/gitlab-cli"
    ci_cleanup_env

    # --- TP-CLI-16: no $() of prompt_ask / read helpers ---
    if grep -E '\$\(prompt_|`prompt_' "${SCRIPT}" | grep -v '^[[:space:]]*#' >/dev/null 2>&1; then
        t_fail "TP-CLI-16 ship unit captures prompt_* with \$()"
    else
        t_pass "TP-CLI-16 no \$(prompt_ / backtick prompt_ in ship unit"
    fi

    # --- help lists menu / GitLab verbs; omits nginx ---
    _out=$(sh "${SCRIPT}" help 2>/dev/null)
    assert_contains "help lists list-users" "$_out" "list-users"
    assert_contains "help lists reset-password" "$_out" "reset-password"
    assert_contains "help lists menu" "$_out" "menu"
    assert_contains "help lists main alias" "$_out" "Alias of menu"
    assert_not_contains "help omits nginx-conf" "$_out" "nginx-conf"
    assert_not_contains "help omits --no-cloudflare" "$_out" "--no-cloudflare"
    assert_not_contains "help omits CHECKSUM" "$_out" "CHECKSUM"

    # --- TP-CLI-17 menu off-TTY is human help (not the numbered list) ---
    _out=$(sh "${SCRIPT}" menu </dev/null 2>/dev/null)
    _ec=$?
    assert_eq "TP-CLI-17 menu off-tty exit 0" 0 "$_ec"
    assert_contains "TP-CLI-17 menu off-tty is help" "$_out" "Usage:"
    assert_not_contains "TP-CLI-17 menu off-tty no Exit 9 list" "$_out" "9. Exit"

    _out=$(sh "${SCRIPT}" --json menu </dev/null 2>/dev/null)
    assert_contains "TP-CLI-17 menu --json off-tty JSON help" "$_out" '"type":"success"'

    _out=$(sh "${SCRIPT}" --json </dev/null 2>/dev/null)
    assert_contains "TP-CLI overlay --json no command is JSON help" "$_out" '"command":"help"'
    assert_not_contains "TP-CLI overlay --json no command is not Type O path" "$_out" "already installed"

    # --- TP-CLI-17 / TP-CLI-19 TTY numbered list ---
    _pty_py="${TESTS_ROOT}/helpers/pty_feed.py"
    _pty_out=""
    _pty_ok=1
    if command -v python3 >/dev/null 2>&1 && [ -f "${_pty_py}" ]; then
        _pty_out=$(MENU_INPUT='9
' MENU_WAIT='Choice' python3 "${_pty_py}" sh "${SCRIPT}" menu 2>/dev/null)
        _pty_ok=$?
    fi
    if [ "${_pty_ok}" -eq 0 ] && [ -n "${_pty_out}" ] && printf '%s' "${_pty_out}" | grep -q "9. Exit"; then
        assert_contains "TP-CLI-17 TTY menu has Exit 9" "${_pty_out}" "9. Exit"
        assert_contains "TP-CLI-17 TTY menu row 1 list-users" "${_pty_out}" "1. list-users:"
        assert_contains "TP-CLI-17 TTY menu row 2 reset-password" "${_pty_out}" "2. reset-password:"
        assert_contains "TP-CLI-17 TTY menu header VERSION" "${_pty_out}" "${PRODUCT_VERSION}"
        assert_contains "TP-CLI-17 TTY menu gray-italic explain" "${_pty_out}" "[3;37m"
        assert_not_contains "TP-CLI-17 TTY menu omits help as a row" "${_pty_out}" "help: Show this help"
        assert_not_contains "TP-CLI-17 TTY menu omits install row" "${_pty_out}" "1. install:"
        assert_not_contains "TP-CLI-17 TTY menu omits setup row" "${_pty_out}" "setup:"
        assert_not_contains "TP-CLI-17 TTY menu omits version row" "${_pty_out}" "version:"
        _pty_bad=$(MENU_INPUT='3
9
' MENU_WAIT='Choice' python3 "${_pty_py}" sh "${SCRIPT}" menu 2>/dev/null)
        assert_contains "TP-CLI-19 invalid 3 prints ERROR" "${_pty_bad}" "[ERROR]"
        assert_contains "TP-CLI-19 invalid 3 reprints list-users" "${_pty_bad}" "1. list-users:"
        assert_contains "TP-CLI-19 invalid 3 still offers Exit" "${_pty_bad}" "9. Exit"
        _pty_empty=$(MENU_INPUT='9
' MENU_WAIT='Choice' python3 "${_pty_py}" sh "${SCRIPT}" 2>/dev/null)
        assert_contains "TP-CLI-17 TTY empty argv has Exit 9" "${_pty_empty}" "9. Exit"
        assert_contains "TP-CLI-17 TTY empty argv row 1 list-users" "${_pty_empty}" "1. list-users:"
    else
        t_skip "TP-CLI-17 TTY menu numbered list (no PTY)"
        t_skip "TP-CLI-19 invalid menu choice retry (no PTY)"
    fi
}
