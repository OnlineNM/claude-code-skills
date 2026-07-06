# Telegram Notification Enhancements Implementation Plan

> **For agentic workers:** Use superpowers:subagent-driven-development to implement this plan task-by-task. Each task must follow superpowers:test-driven-development.

**Goal:** Make `plugins/telegram`'s Telegram sends robust (retry, timeout, response validation, truncation) and eliminate the confirmed double-send bug where `notify-waiting.sh` is triggered by both the `Notification` and `PermissionRequest` hook events for the same "waiting for you" moment.

**Architecture:** A new shared file, `plugins/telegram/scripts/telegram-utils.sh`, holds constants, an atomic filesystem-lock dedup mechanism, and a robust `send_telegram_message` (retry/timeout/validation). It is sourced by both `notify-waiting.sh` and `job-done.sh` immediately after `load-env.sh`. Dedup applies only inside `notify-waiting.sh` (shared by `Notification`/`PermissionRequest`); `job-done.sh` (`Stop` event) gets the robust send but no dedup lock. `load-env.sh` and the `notify`/`status`/`toggle` skills stay untouched.

**Tech Stack:** bash (`set -euo pipefail`), `curl`, `python3` (JSON parsing, response validation, debounce sleep), `shasum`/`sha256sum`, `stat`, `date`, `mktemp`. No new test framework is introduced (none exists in this repo) — tests are plain bash scripts under `plugins/telegram/scripts/tests/`, using a fake `curl` on `PATH` and direct filesystem assertions.

## Global Constraints

- Source of truth: `docs/telegram-notification-enhancements-DESIGN.md` (locked spec, 6 adversarial review rounds) — its bash snippets for locking functions are the exact implementation target, not a starting point for redesign.
- Constants (exact values): `MAX_MESSAGE_LENGTH=4096`, `CURL_CONNECT_TIMEOUT=5`, `CURL_MAX_TIME=5`, `MAX_RETRIES=2`, `LOCK_DIR="${HOME-}/.claude/telegram-locks"`, `LOCK_TTL=5`, `NOTIFICATION_DEBOUNCE=1.5`.
- Env var names stay exactly `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`.
- `load-env.sh` is NOT modified. Skills `notify`/`status`/`toggle` are NOT modified.
- Plain text only — `send_telegram_message` never sends `parse_mode`. No MarkdownV2 escaping (out of scope).
- Silent-fail behavior preserved: both hook scripts always `exit 0`, regardless of send outcome, so a hook failure never blocks Claude Code.
- Dedup lock scope is `notify-waiting.sh` only — never added to `job-done.sh`.
- `PermissionRequest` messages are never suppressed by dedup (they always claim-and-send, via `mark_claim`, unconditionally).
- Fail-open everywhere locking infra is unavailable (missing `$HOME`, unwritable `LOCK_DIR`, missing dedup key): log a warning to stderr, send the message anyway.

---

### Task 1: `telegram-utils.sh` — constants and locking/dedup primitives

**Files:**
- Create: `plugins/telegram/scripts/telegram-utils.sh`
- Test: `plugins/telegram/scripts/tests/test_helpers.sh` (new shared test helper, used by all later test tasks too)
- Test: `plugins/telegram/scripts/tests/test_locking.sh`

**Interfaces:**
- Produces (used by Tasks 2-4): constants `MAX_MESSAGE_LENGTH`, `CURL_CONNECT_TIMEOUT`, `CURL_MAX_TIME`, `MAX_RETRIES`, `LOCK_DIR`, `LOCK_TTL`, `NOTIFICATION_DEBOUNCE`; functions `hash_session_id(id) -> stdout hash`, `lock_path_for(key) -> stdout path`, `ensure_lock_dir() -> 0/1`, `cleanup_stale_locks() -> 0/1`, `has_active_lock(key) -> 0/1`, `try_claim(key) -> 0/1`, `mark_claim(key) -> 0/1` (ignorable by caller).

- [ ] **Step 1: Write the test helper file**

Create `plugins/telegram/scripts/tests/test_helpers.sh`:

```bash
#!/usr/bin/env bash
# Shared helpers for plugins/telegram shell tests. Sourced by every test_*.sh file.

TESTS_PASSED=0
TESTS_FAILED=0

assert_eq() {
  local expected="$1" actual="$2" msg="${3:-assert_eq}"
  if [ "$expected" = "$actual" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: $msg — expected [$expected], got [$actual]" >&2
  fi
}

assert_true() {
  local cond_desc="$1" result="$2"
  if [ "$result" -eq 0 ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: $cond_desc — expected success, got exit code $result" >&2
  fi
}

assert_false() {
  local cond_desc="$1" result="$2"
  if [ "$result" -ne 0 ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "FAIL: $cond_desc — expected failure, got success" >&2
  fi
}

# Creates a fake `curl` on PATH that logs each invocation to $FAKE_CURL_LOG and
# writes a canned Telegram API response body. Controlled by env vars:
#   FAKE_CURL_HTTP_CODE (default 200), FAKE_CURL_OK (default true)
setup_fake_curl() {
  FAKE_BIN_DIR=$(mktemp -d)
  FAKE_CURL_LOG=$(mktemp)
  export FAKE_BIN_DIR FAKE_CURL_LOG
  cat > "$FAKE_BIN_DIR/curl" <<'EOF'
#!/usr/bin/env bash
echo "call" >> "$FAKE_CURL_LOG"
out_file=""
args=("$@")
for i in "${!args[@]}"; do
  if [ "${args[$i]}" = "-o" ]; then
    out_file="${args[$((i+1))]}"
  fi
done
code="${FAKE_CURL_HTTP_CODE:-200}"
ok="${FAKE_CURL_OK:-true}"
if [ -n "$out_file" ]; then
  printf '{"ok": %s}' "$ok" > "$out_file"
fi
printf '%s' "$code"
EOF
  chmod +x "$FAKE_BIN_DIR/curl"
  ORIGINAL_PATH="$PATH"
  PATH="$FAKE_BIN_DIR:$PATH"
  export PATH
}

teardown_fake_curl() {
  PATH="$ORIGINAL_PATH"
  export PATH
  rm -rf "$FAKE_BIN_DIR"
  rm -f "$FAKE_CURL_LOG"
}

fake_curl_call_count() {
  [ -f "$FAKE_CURL_LOG" ] && wc -l < "$FAKE_CURL_LOG" | tr -d ' ' || echo 0
}

test_summary() {
  echo ""
  echo "Passed: $TESTS_PASSED, Failed: $TESTS_FAILED"
  [ "$TESTS_FAILED" -eq 0 ]
}
```

- [ ] **Step 2: Write the failing test for locking primitives**

Create `plugins/telegram/scripts/tests/test_locking.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/test_helpers.sh"

TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"

. "$SCRIPT_DIR/../telegram-utils.sh"

# hash_session_id: deterministic, distinguishes different inputs
h1="$(hash_session_id "session-a")"
h2="$(hash_session_id "session-a")"
h3="$(hash_session_id "session-b")"
assert_eq "$h1" "$h2" "hash_session_id is deterministic"
[ "$h1" != "$h3" ]; assert_true "hash_session_id differs for different input" $?

# ensure_lock_dir creates dir with 700 perms
ensure_lock_dir
assert_true "ensure_lock_dir succeeds" $?
perms=$(stat -f %Lp "$LOCK_DIR" 2>/dev/null || stat -c %a "$LOCK_DIR" 2>/dev/null)
assert_eq "700" "$perms" "LOCK_DIR has 700 perms"

# try_claim succeeds first time, fails second time for same key
rm -f "$LOCK_DIR"/*.lock 2>/dev/null
try_claim "key-1"; assert_true "try_claim succeeds first time" $?
try_claim "key-1"; assert_false "try_claim fails second time (already claimed)" $?

# mark_claim always succeeds/overwrites even if a lock already exists
try_claim "key-2"
mtime_before=$(stat -f %m "$(lock_path_for key-2)" 2>/dev/null || stat -c %Y "$(lock_path_for key-2)" 2>/dev/null)
sleep 1
mark_claim "key-2"
mtime_after=$(stat -f %m "$(lock_path_for key-2)" 2>/dev/null || stat -c %Y "$(lock_path_for key-2)" 2>/dev/null)
[ "$mtime_after" -ge "$mtime_before" ]; assert_true "mark_claim refreshes mtime on existing lock" $?

# has_active_lock reflects existence
try_claim "key-3"
has_active_lock "key-3"; assert_true "has_active_lock true for claimed key" $?
has_active_lock "key-unclaimed"; assert_false "has_active_lock false for unclaimed key" $?

# cleanup_stale_locks removes locks older than LOCK_TTL
try_claim "key-stale"
lock_file="$(lock_path_for key-stale)"
touch -t "$(date -v-10S +%Y%m%d%H%M.%S 2>/dev/null || date -d '-10 seconds' +%Y%m%d%H%M.%S)" "$lock_file" 2>/dev/null
cleanup_stale_locks
[ ! -e "$lock_file" ]; assert_true "cleanup_stale_locks removes expired lock" $?

rm -rf "$TEST_HOME"
test_summary
exit $?
```

- [ ] **Step 3: Run test to verify it fails**

Run: `bash plugins/telegram/scripts/tests/test_locking.sh`
Expected: FAIL immediately with "No such file or directory" (`telegram-utils.sh` does not exist yet).

- [ ] **Step 4: Write `telegram-utils.sh` (constants + locking primitives)**

Create `plugins/telegram/scripts/telegram-utils.sh`:

```bash
#!/usr/bin/env bash
# Shared utilities for Telegram hook scripts: constants, locking/dedup, and robust HTTP send.
# Sourced by notify-waiting.sh and job-done.sh immediately after load-env.sh.

MAX_MESSAGE_LENGTH=4096
CURL_CONNECT_TIMEOUT=5
CURL_MAX_TIME=5
MAX_RETRIES=2
LOCK_DIR="${HOME-}/.claude/telegram-locks"
LOCK_TTL=5
NOTIFICATION_DEBOUNCE=1.5

hash_session_id() {
  local id="$1" full hash
  if command -v shasum >/dev/null 2>&1; then
    full=$(printf '%s' "$id" | shasum -a 256)
  else
    full=$(printf '%s' "$id" | sha256sum)
  fi
  read -r hash _ <<< "$full"
  printf '%s' "$hash"
}

lock_path_for() { printf '%s/%s.lock' "$LOCK_DIR" "$(hash_session_id "$1")"; }

# Return 1 if the lock dir cannot be prepared (permissions etc.) — callers
# treat that as "locking unavailable" and fail open.
ensure_lock_dir() {
  if ! mkdir -p "$LOCK_DIR" 2>/dev/null || ! chmod 700 "$LOCK_DIR" 2>/dev/null; then
    echo "Telegram: cannot prepare lock dir $LOCK_DIR — dedup dezactivat pentru acest apel" >&2
    return 1
  fi
  return 0
}

cleanup_stale_locks() {
  ensure_lock_dir || return 1
  for f in "$LOCK_DIR"/*.lock; do
    [ -e "$f" ] || continue
    local mtime now
    mtime=$(stat -f %m "$f" 2>/dev/null || stat -c %Y "$f" 2>/dev/null) || { echo "Telegram: stat failed on $f, skipping" >&2; continue; }
    now=$(date +%s)
    [ "$((now - mtime))" -gt "$LOCK_TTL" ] && rm -f "$f"
  done
  return 0
}

# Notification: fail-open (treat unlocked infra as "not locked" — better an extra
# notification than a silently-lost one).
has_active_lock() {
  cleanup_stale_locks || return 1
  [ -e "$(lock_path_for "$1")" ]
}

# Notification: atomic creation (O_EXCL via noclobber) — combines check + create
# into a single step, eliminating the check-then-send race gap.
# If the lock dir is unavailable, treat as "claim won" (fail-open — send anyway).
try_claim() {
  cleanup_stale_locks || return 0
  local lock_file; lock_file="$(lock_path_for "$1")"
  if ( set -o noclobber; : > "$lock_file" ) 2>/dev/null; then
    return 0
  else
    return 1
  fi
}

# PermissionRequest: clears expired locks, then unconditionally overwrites
# (fresh mtime) — never blocks sending.
mark_claim() {
  cleanup_stale_locks || { : > "$(lock_path_for "$1")" 2>/dev/null; return 1; }
  : > "$(lock_path_for "$1")" 2>/dev/null
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `bash plugins/telegram/scripts/tests/test_locking.sh`
Expected: `Passed: 8, Failed: 0` (exit code 0).

- [ ] **Step 6: Commit**

```bash
git add plugins/telegram/scripts/telegram-utils.sh plugins/telegram/scripts/tests/test_helpers.sh plugins/telegram/scripts/tests/test_locking.sh
git commit -m "feat(telegram): add telegram-utils.sh with atomic-claim dedup locking"
```

---

### Task 2: Ported utility functions — `check_dependencies`, `validate_config`, `sanitize_message`, `send_telegram_message`

**Files:**
- Modify: `plugins/telegram/scripts/telegram-utils.sh` (append functions)
- Test: `plugins/telegram/scripts/tests/test_send_utils.sh`

**Interfaces:**
- Consumes: `MAX_MESSAGE_LENGTH`, `CURL_CONNECT_TIMEOUT`, `CURL_MAX_TIME`, `MAX_RETRIES` from Task 1.
- Produces (used by Tasks 3-4): `check_dependencies() -> 0/1`, `validate_config(token, chat_id) -> 0/1`, `sanitize_message(msg) -> stdout cleaned/truncated msg`, `send_telegram_message(token, chat_id, message) -> 0/1`.

- [ ] **Step 1: Write the failing test**

Create `plugins/telegram/scripts/tests/test_send_utils.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/test_helpers.sh"

TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"

. "$SCRIPT_DIR/../telegram-utils.sh"

# validate_config
validate_config "123456:AbC-DeF_123" "12345"; assert_true "validate_config accepts numeric chat_id" $?
validate_config "123456:AbC-DeF_123" "@my_channel"; assert_true "validate_config accepts @channel chat_id" $?
validate_config "not-a-token" "12345"; assert_false "validate_config rejects bad token" $?
validate_config "123456:AbC-DeF_123" "not valid"; assert_false "validate_config rejects bad chat_id" $?

# sanitize_message
raw=$'line one\tstill line one\x01\x02\nline two'
clean="$(sanitize_message "$raw")"
case "$clean" in
  *$'\n'*) assert_true "sanitize_message preserves newlines" 0 ;;
  *) assert_true "sanitize_message preserves newlines" 1 ;;
esac
long=$(printf 'a%.0s' $(seq 1 5000))
truncated="$(sanitize_message "$long")"
assert_eq "4096" "${#truncated}" "sanitize_message truncates to MAX_MESSAGE_LENGTH"
assert_eq "..." "${truncated: -3}" "sanitize_message appends ellipsis on truncation"

# check_dependencies passes in a normal dev environment
check_dependencies; assert_true "check_dependencies passes when tools present" $?

# send_telegram_message: success on first attempt
setup_fake_curl
send_telegram_message "111:tok" "222" "hello"
assert_true "send_telegram_message succeeds on 200+ok:true" $?
assert_eq "1" "$(fake_curl_call_count)" "send_telegram_message makes exactly 1 call on success"
teardown_fake_curl

# send_telegram_message: exhausts MAX_RETRIES on persistent failure
setup_fake_curl
export FAKE_CURL_HTTP_CODE=401 FAKE_CURL_OK=false
send_telegram_message "111:tok" "222" "hello"
assert_false "send_telegram_message fails after exhausting retries" $?
assert_eq "$MAX_RETRIES" "$(fake_curl_call_count)" "send_telegram_message retries exactly MAX_RETRIES times"
unset FAKE_CURL_HTTP_CODE FAKE_CURL_OK
teardown_fake_curl

rm -rf "$TEST_HOME"
test_summary
exit $?
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash plugins/telegram/scripts/tests/test_send_utils.sh`
Expected: FAIL with "validate_config: command not found" (functions don't exist yet).

- [ ] **Step 3: Append the utility functions to `telegram-utils.sh`**

Append to `plugins/telegram/scripts/telegram-utils.sh`:

```bash
# Verifies every external command telegram-utils.sh/notify-waiting.sh/job-done.sh
# actually use, plus that $HOME is set. Called after sourcing, before validate_config.
check_dependencies() {
  local missing=() cmd
  for cmd in curl python3 tr stat date mktemp chmod mkdir rm; do
    command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
  done
  if ! command -v shasum >/dev/null 2>&1 && ! command -v sha256sum >/dev/null 2>&1; then
    missing+=("shasum-or-sha256sum")
  fi
  if [ -z "${HOME:-}" ]; then
    missing+=('$HOME (not set)')
  fi
  if [ "${#missing[@]}" -gt 0 ]; then
    echo "Telegram: missing required dependencies: ${missing[*]}" >&2
    return 1
  fi
  return 0
}

validate_config() {
  local token="$1" chat_id="$2"
  if ! [[ "$token" =~ ^[0-9]+:[a-zA-Z0-9_-]+$ ]]; then
    echo "Telegram: TELEGRAM_BOT_TOKEN has invalid format" >&2
    return 1
  fi
  if ! [[ "$chat_id" =~ ^-?[0-9]+$ ]] && ! [[ "$chat_id" =~ ^@[^[:space:]]+$ ]]; then
    echo "Telegram: TELEGRAM_CHAT_ID has invalid format" >&2
    return 1
  fi
  return 0
}

sanitize_message() {
  local msg="$1" clean
  clean=$(printf '%s' "$msg" | tr -d '\000-\010\013\014\016-\037')
  if [ "${#clean}" -gt "$MAX_MESSAGE_LENGTH" ]; then
    clean="${clean:0:$((MAX_MESSAGE_LENGTH - 3))}..."
  fi
  printf '%s' "$clean"
}

send_telegram_message() {
  local token="$1" chat_id="$2" message="$3"
  local attempt=1 tmp_body http_code curl_exit

  tmp_body=$(mktemp) || { echo "Telegram: mktemp failed" >&2; return 1; }

  while [ "$attempt" -le "$MAX_RETRIES" ]; do
    if http_code=$(curl -s -o "$tmp_body" -w '%{http_code}' -X POST \
        --connect-timeout "$CURL_CONNECT_TIMEOUT" --max-time "$CURL_MAX_TIME" \
        --data-urlencode "chat_id=${chat_id}" --data-urlencode "text=${message}" \
        "https://api.telegram.org/bot${token}/sendMessage"); then
      curl_exit=0
    else
      curl_exit=$?
      http_code="${http_code:-000}"
    fi

    if [ "$curl_exit" -eq 0 ] && [ "$http_code" = "200" ] && python3 -c "
import json, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    sys.exit(0 if data.get('ok') is True else 1)
except Exception:
    sys.exit(1)
" "$tmp_body"; then
      rm -f "$tmp_body"
      return 0
    fi

    echo "Telegram: send attempt $attempt/$MAX_RETRIES failed (http=$http_code, curl_exit=$curl_exit)" >&2
    attempt=$((attempt + 1))
    [ "$attempt" -le "$MAX_RETRIES" ] && sleep 2
  done

  rm -f "$tmp_body"
  echo "Telegram: send_telegram_message exhausted $MAX_RETRIES retries" >&2
  return 1
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash plugins/telegram/scripts/tests/test_send_utils.sh`
Expected: `Passed: 10, Failed: 0` (exit code 0). Takes ~2s due to the intentional retry backoff.

- [ ] **Step 5: Commit**

```bash
git add plugins/telegram/scripts/telegram-utils.sh plugins/telegram/scripts/tests/test_send_utils.sh
git commit -m "feat(telegram): add check_dependencies/validate_config/sanitize_message/send_telegram_message"
```

---

### Task 3: Integrate dedup + robust send into `notify-waiting.sh`

**Files:**
- Modify: `plugins/telegram/scripts/notify-waiting.sh` (full rewrite of the send path)
- Test: `plugins/telegram/scripts/tests/test_notify_waiting.sh`

**Interfaces:**
- Consumes: everything from `telegram-utils.sh` (Tasks 1-2).
- Produces: no new interfaces (this is the leaf hook script).

- [ ] **Step 1: Write the failing test**

Create `plugins/telegram/scripts/tests/test_notify_waiting.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/test_helpers.sh"

export CLAUDE_PLUGIN_ROOT="$SCRIPT_DIR/.."
TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"
export TELEGRAM_BOT_TOKEN="123456:AbC-DeF_123"
export TELEGRAM_CHAT_ID="12345"

. "$SCRIPT_DIR/../telegram-utils.sh"
NOTIFY_SCRIPT="$SCRIPT_DIR/../notify-waiting.sh"

notification_payload() { printf '{"session_id": "%s", "title": "t", "message": "m"}' "$1"; }
permission_payload()   { printf '{"session_id": "%s", "tool_name": "Bash", "tool_input": {"command": "ls"}}' "$1"; }

setup_fake_curl

# Normal PermissionRequest send
permission_payload "sess-1" | bash "$NOTIFY_SCRIPT" >/dev/null 2>&1
assert_eq "1" "$(fake_curl_call_count)" "PermissionRequest sends exactly one message"
: > "$FAKE_CURL_LOG"; rm -f "$LOCK_DIR"/*.lock 2>/dev/null

# Normal Notification send (no concurrent PermissionRequest)
notification_payload "sess-2" | bash "$NOTIFY_SCRIPT" >/dev/null 2>&1
assert_eq "1" "$(fake_curl_call_count)" "Notification alone sends exactly one message"
: > "$FAKE_CURL_LOG"; rm -f "$LOCK_DIR"/*.lock 2>/dev/null

# Concurrency test: near-simultaneous Notification + PermissionRequest, same
# session → exactly one message sent (the confirmed bug scenario)
notification_payload "sess-3" | bash "$NOTIFY_SCRIPT" >/dev/null 2>&1 &
pid_notif=$!
permission_payload "sess-3" | bash "$NOTIFY_SCRIPT" >/dev/null 2>&1 &
pid_perm=$!
wait "$pid_notif" "$pid_perm"
assert_eq "1" "$(fake_curl_call_count)" "concurrent Notification+PermissionRequest send exactly one message"
: > "$FAKE_CURL_LOG"; rm -f "$LOCK_DIR"/*.lock 2>/dev/null

# Ordering: Notification first, PermissionRequest <1.5s after → exactly one message
notification_payload "sess-4" | bash "$NOTIFY_SCRIPT" >/dev/null 2>&1 &
pid_notif=$!
sleep 0.3
permission_payload "sess-4" | bash "$NOTIFY_SCRIPT" >/dev/null 2>&1
wait "$pid_notif"
assert_eq "1" "$(fake_curl_call_count)" "Notification-then-PermissionRequest sends exactly one message"
: > "$FAKE_CURL_LOG"; rm -f "$LOCK_DIR"/*.lock 2>/dev/null

# Ordering: PermissionRequest first, Notification immediately after → exactly one message
permission_payload "sess-5" | bash "$NOTIFY_SCRIPT" >/dev/null 2>&1
notification_payload "sess-5" | bash "$NOTIFY_SCRIPT" >/dev/null 2>&1
assert_eq "1" "$(fake_curl_call_count)" "PermissionRequest-then-Notification sends exactly one message"
: > "$FAKE_CURL_LOG"; rm -f "$LOCK_DIR"/*.lock 2>/dev/null

# Expired lock + new PermissionRequest → mark_claim overwrites and still sends
try_claim "sess-6" >/dev/null 2>&1 || true
lock_file="$(lock_path_for sess-6)"
touch -t "$(date -v-10S +%Y%m%d%H%M.%S 2>/dev/null || date -d '-10 seconds' +%Y%m%d%H%M.%S)" "$lock_file" 2>/dev/null
permission_payload "sess-6" | bash "$NOTIFY_SCRIPT" >/dev/null 2>&1
assert_eq "1" "$(fake_curl_call_count)" "expired lock + new PermissionRequest still sends"
: > "$FAKE_CURL_LOG"; rm -f "$LOCK_DIR"/*.lock 2>/dev/null

# Lock dir inaccessible → fail-open (message still sent, warning on stderr).
# chmod 000 must target the PARENT of LOCK_DIR (~/.claude), since LOCK_DIR
# itself doesn't exist yet on a fresh run — mkdir -p fails when it can't
# create an entry under a non-writable parent.
mkdir -p "$TEST_HOME/.claude"
chmod 000 "$TEST_HOME/.claude"
stderr_out=$(permission_payload "sess-7" | bash "$NOTIFY_SCRIPT" 2>&1 >/dev/null)
chmod 700 "$TEST_HOME/.claude"
assert_eq "1" "$(fake_curl_call_count)" "inaccessible lock dir still sends (fail-open)"
case "$stderr_out" in
  *"cannot prepare lock dir"*) assert_true "fail-open logs a warning" 0 ;;
  *) assert_true "fail-open logs a warning" 1 ;;
esac
: > "$FAKE_CURL_LOG"; rm -f "$LOCK_DIR"/*.lock 2>/dev/null

# session_id missing, cwd present → dedup uses cwd fallback, with warning
notification_no_session() { printf '{"cwd": "%s", "title": "t", "message": "m"}' "$1"; }
stderr_out=$(notification_no_session "/tmp/some-project" | bash "$NOTIFY_SCRIPT" 2>&1 >/dev/null)
assert_eq "1" "$(fake_curl_call_count)" "missing session_id with cwd fallback still sends"
case "$stderr_out" in
  *"dedup using cwd fallback"*) assert_true "cwd fallback warning logged" 0 ;;
  *) assert_true "cwd fallback warning logged" 1 ;;
esac
: > "$FAKE_CURL_LOG"; rm -f "$LOCK_DIR"/*.lock 2>/dev/null

# Neither session_id nor cwd present → fail-open, message still sent
bare_notification() { printf '{"title": "t", "message": "m"}'; }
stderr_out=$(bare_notification | bash "$NOTIFY_SCRIPT" 2>&1 >/dev/null)
assert_eq "1" "$(fake_curl_call_count)" "missing session_id and cwd still sends (fail-open)"
case "$stderr_out" in
  *"dedup key unavailable"*) assert_true "no-key fail-open warning logged" 0 ;;
  *) assert_true "no-key fail-open warning logged" 1 ;;
esac

teardown_fake_curl
rm -rf "$TEST_HOME"
test_summary
exit $?
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash plugins/telegram/scripts/tests/test_notify_waiting.sh`
Expected: FAIL — the concurrency test asserts "exactly one message" but the current `notify-waiting.sh` has no dedup, so two calls will be logged (`fake_curl_call_count` returns `2`, not `1`).

- [ ] **Step 3: Rewrite `notify-waiting.sh`**

Replace `plugins/telegram/scripts/notify-waiting.sh` with:

```bash
#!/usr/bin/env bash
# Hook script: sends a Telegram notification when Claude Code needs user attention.
# Handles both Notification events (waiting for answer) and PermissionRequest events
# (approve action). Deduplicates near-simultaneous Notification/PermissionRequest
# sends for the same session via an atomic filesystem lock (see telegram-utils.sh).

set -euo pipefail

# shellcheck source=scripts/load-env.sh
. "${CLAUDE_PLUGIN_ROOT}/scripts/load-env.sh"
# shellcheck source=scripts/telegram-utils.sh
. "${CLAUDE_PLUGIN_ROOT}/scripts/telegram-utils.sh"

check_dependencies || exit 0

[ -f "$HOME/.claude/.notifications-disabled" ] && exit 0

if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
  echo "Telegram credentials not set; skipping notification." >&2
  exit 0
fi

validate_config "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID" || exit 0

HOOK_DATA=$(cat)

TOOL_NAME=$(printf '%s' "$HOOK_DATA" | python3 -c "import sys, json; print(json.load(sys.stdin).get('tool_name', ''))" 2>/dev/null || true)
SESSION_ID=$(printf '%s' "$HOOK_DATA" | python3 -c "import sys, json; print(json.load(sys.stdin).get('session_id', ''))" 2>/dev/null || true)

if [ -n "$SESSION_ID" ]; then
  DEDUP_KEY="$SESSION_ID"
else
  CWD_VAL=$(printf '%s' "$HOOK_DATA" | python3 -c "import sys, json; print(json.load(sys.stdin).get('cwd', ''))" 2>/dev/null || true)
  if [ -n "$CWD_VAL" ]; then
    echo "Telegram: dedup using cwd fallback" >&2
    DEDUP_KEY="$CWD_VAL"
  else
    echo "Telegram: dedup key unavailable (no session_id or cwd) — sending without dedup" >&2
    DEDUP_KEY=""
  fi
fi

MSG=$(printf '%s' "$HOOK_DATA" | python3 -c "
import sys, json

data = json.load(sys.stdin)
tool_name = data.get('tool_name', '')

if tool_name:
    tool_input = data.get('tool_input', {})
    lines = ['Claude needs your approval!', '', f'Tool: {tool_name}']

    if tool_name == 'Bash':
        cmd = tool_input.get('command', '')
        lines.append(f'Command: {cmd[:400]}')
    elif tool_name in ('Write', 'Edit', 'NotebookEdit'):
        path = tool_input.get('file_path', tool_input.get('notebook_path', ''))
        lines.append(f'File: {path}')
    elif tool_name == 'WebFetch':
        lines.append(f'URL: {tool_input.get(\"url\", \"\")}')
    elif tool_name == 'WebSearch':
        lines.append(f'Query: {tool_input.get(\"query\", \"\")}')
    else:
        for k, v in list(tool_input.items())[:3]:
            lines.append(f'{k}: {str(v)[:150]}')
else:
    title = data.get('title', '')
    message = data.get('message', '')
    lines = ['Claude needs your attention!']
    if title:
        lines.append(f'Title: {title}')
    if message:
        lines.append('')
        lines.extend(message.strip().splitlines()[-5:])

print('\n'.join(lines))
" 2>/dev/null || echo "Claude needs your attention!")

MSG=$(sanitize_message "$MSG")

if [ -n "$TOOL_NAME" ]; then
  # PermissionRequest: always claim and send, never suppressed.
  if [ -n "$DEDUP_KEY" ]; then
    mark_claim "$DEDUP_KEY" || true
  fi
  send_telegram_message "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID" "$MSG" || true
else
  # Notification: skip if already claimed, else debounce then try to claim.
  if [ -n "$DEDUP_KEY" ] && has_active_lock "$DEDUP_KEY"; then
    exit 0
  fi
  python3 -c 'import time, sys; time.sleep(float(sys.argv[1]))' "$NOTIFICATION_DEBOUNCE"
  if [ -z "$DEDUP_KEY" ] || try_claim "$DEDUP_KEY"; then
    send_telegram_message "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID" "$MSG" || true
  fi
fi

exit 0
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash plugins/telegram/scripts/tests/test_notify_waiting.sh`
Expected: `Passed: 12, Failed: 0` (exit code 0). Takes roughly 10-15s (several 1.5s debounce waits).

- [ ] **Step 5: Commit**

```bash
git add plugins/telegram/scripts/notify-waiting.sh plugins/telegram/scripts/tests/test_notify_waiting.sh
git commit -m "fix(telegram): dedup Notification/PermissionRequest sends via atomic claim"
```

---

### Task 4: Integrate robust send into `job-done.sh` (no dedup)

**Files:**
- Modify: `plugins/telegram/scripts/job-done.sh`
- Test: `plugins/telegram/scripts/tests/test_job_done.sh`

**Interfaces:**
- Consumes: `check_dependencies`, `validate_config`, `sanitize_message`, `send_telegram_message` from `telegram-utils.sh`.
- Produces: none (leaf hook script).

- [ ] **Step 1: Write the failing test**

Create `plugins/telegram/scripts/tests/test_job_done.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/test_helpers.sh"

export CLAUDE_PLUGIN_ROOT="$SCRIPT_DIR/.."
TEST_HOME=$(mktemp -d)
export HOME="$TEST_HOME"
export TELEGRAM_BOT_TOKEN="123456:AbC-DeF_123"
export TELEGRAM_CHAT_ID="12345"

JOB_DONE_SCRIPT="$SCRIPT_DIR/../job-done.sh"

setup_fake_curl

# No transcript present → falls back to "Task completed."
printf '{"session_id": "no-such-session"}' | bash "$JOB_DONE_SCRIPT" >/dev/null 2>&1
assert_eq "1" "$(fake_curl_call_count)" "job-done sends exactly one message when transcript is missing"
: > "$FAKE_CURL_LOG"

# Transcript present → last assistant message is extracted and sent
mkdir -p "$TEST_HOME/.claude/projects/proj-a"
cat > "$TEST_HOME/.claude/projects/proj-a/sess-99.jsonl" <<'EOF'
{"message": {"role": "user", "content": "hi"}}
{"message": {"role": "assistant", "content": [{"type": "text", "text": "All done here."}]}}
EOF
printf '{"session_id": "sess-99"}' | bash "$JOB_DONE_SCRIPT" >/dev/null 2>&1
assert_eq "1" "$(fake_curl_call_count)" "job-done sends exactly one message with a real transcript"
: > "$FAKE_CURL_LOG"

# Invalid token format → exit 0, nothing sent
(
  export TELEGRAM_BOT_TOKEN="bad-token"
  printf '{"session_id": "sess-99"}' | bash "$JOB_DONE_SCRIPT" >/dev/null 2>&1
)
assert_eq "0" "$(fake_curl_call_count)" "job-done sends nothing when token format is invalid"
: > "$FAKE_CURL_LOG"

# API failure (persistent) → retries twice then exits 0 without crashing
export FAKE_CURL_HTTP_CODE=500 FAKE_CURL_OK=false
printf '{"session_id": "sess-99"}' | bash "$JOB_DONE_SCRIPT" >/dev/null 2>&1
exit_code=$?
assert_eq "0" "$exit_code" "job-done exits 0 even when Telegram API call fails"
assert_eq "2" "$(fake_curl_call_count)" "job-done retries MAX_RETRIES (2) times on failure"
unset FAKE_CURL_HTTP_CODE FAKE_CURL_OK

teardown_fake_curl
rm -rf "$TEST_HOME"
test_summary
exit $?
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bash plugins/telegram/scripts/tests/test_job_done.sh`
Expected: FAIL — the current `job-done.sh` has no `validate_config`, so the "invalid token format" assertion fails (a message is sent regardless of token format: `fake_curl_call_count` returns `1`, not `0`).

- [ ] **Step 3: Rewrite `job-done.sh`**

Replace `plugins/telegram/scripts/job-done.sh` with:

```bash
#!/usr/bin/env bash
# Hook script: sends a Telegram notification when Claude Code finishes a task.
# Extracts the last assistant message from the transcript and sends it via Telegram.
# Triggered by the Stop hook event. No dedup lock here — see DESIGN.md "Key decisions"
# (the confirmed double-send bug is strictly between Notification/PermissionRequest).

set -euo pipefail

# shellcheck source=scripts/load-env.sh
. "${CLAUDE_PLUGIN_ROOT}/scripts/load-env.sh"
# shellcheck source=scripts/telegram-utils.sh
. "${CLAUDE_PLUGIN_ROOT}/scripts/telegram-utils.sh"

check_dependencies || exit 0

[ -f "$HOME/.claude/.notifications-disabled" ] && exit 0

if [ -z "${TELEGRAM_BOT_TOKEN:-}" ] || [ -z "${TELEGRAM_CHAT_ID:-}" ]; then
  echo "Telegram credentials not set; skipping notification." >&2
  exit 0
fi

validate_config "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID" || exit 0

HOOK_DATA=$(cat)

LAST_MSG=$(echo "$HOOK_DATA" | python3 -c "
import sys, json, pathlib

data = json.load(sys.stdin)
session_id = data.get('session_id', '')

if session_id:
    home = pathlib.Path.home()
    projects_dir = home / '.claude' / 'projects'
    transcript_file = None

    if projects_dir.exists():
        for f in projects_dir.rglob(f'{session_id}.jsonl'):
            transcript_file = f
            break

    if transcript_file and transcript_file.exists():
        content = ''
        with open(transcript_file) as f:
            for line in f:
                try:
                    entry = json.loads(line)
                    msg = entry.get('message', entry)
                    if msg.get('role') == 'assistant':
                        c = msg.get('content', '')
                        if isinstance(c, list):
                            text_parts = [
                                b.get('text', '')
                                for b in c
                                if isinstance(b, dict) and b.get('type') == 'text'
                            ]
                            c = ' '.join(text_parts)
                        if str(c).strip():
                            content = str(c).strip()
                except Exception:
                    pass

        if content:
            lines = [l for l in content.splitlines() if l.strip()]
            print('\n'.join(lines[-5:]))
            sys.exit(0)

print('Task completed.')
" 2>/dev/null || echo "Task completed.")

MSG=$(sanitize_message "Job done!

${LAST_MSG}")

send_telegram_message "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID" "$MSG" || true

exit 0
```

- [ ] **Step 4: Run test to verify it passes**

Run: `bash plugins/telegram/scripts/tests/test_job_done.sh`
Expected: `Passed: 4, Failed: 0` (exit code 0). Takes ~2s due to the retry-backoff scenario.

- [ ] **Step 5: Commit**

```bash
git add plugins/telegram/scripts/job-done.sh plugins/telegram/scripts/tests/test_job_done.sh
git commit -m "feat(telegram): add retry/timeout/validation to job-done.sh"
```

---

### Task 5: Full suite runner + manual acceptance pass

**Files:**
- Create: `plugins/telegram/scripts/tests/run_all.sh`

**Interfaces:**
- Consumes: all `test_*.sh` files from Tasks 1-4.
- Produces: a single pass/fail signal for the whole plugin.

- [ ] **Step 1: Write the test runner**

Create `plugins/telegram/scripts/tests/run_all.sh`:

```bash
#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

overall=0
for t in "$SCRIPT_DIR"/test_*.sh; do
  echo "=== Running $(basename "$t") ==="
  bash "$t"
  status=$?
  if [ "$status" -ne 0 ]; then
    overall=1
    echo "=== FAILED: $(basename "$t") ==="
  fi
done
exit $overall
```

- [ ] **Step 2: Run the full suite**

Run: `chmod +x plugins/telegram/scripts/tests/run_all.sh && bash plugins/telegram/scripts/tests/run_all.sh`
Expected: every `test_*.sh` reports `Failed: 0`; overall exit code `0`. Total runtime ~20-30s (dominated by the `NOTIFICATION_DEBOUNCE` waits in `test_notify_waiting.sh` and the retry backoffs in `test_send_utils.sh`/`test_job_done.sh`).

- [ ] **Step 3: Manual acceptance pass (from DESIGN.md's own acceptance section)**

With real (or throwaway test-bot) `TELEGRAM_BOT_TOKEN`/`TELEGRAM_CHAT_ID` exported in the shell:

```bash
# Real end-to-end send for both event shapes
echo '{"session_id": "manual-1", "title": "hi", "message": "test notification"}' | bash plugins/telegram/scripts/notify-waiting.sh
echo '{"session_id": "manual-2", "tool_name": "Bash", "tool_input": {"command": "ls -la"}}' | bash plugins/telegram/scripts/notify-waiting.sh
echo '{"session_id": "manual-3"}' | bash plugins/telegram/scripts/job-done.sh
```

Confirm in the actual Telegram chat: exactly 3 messages arrive, correctly formatted, no duplicates. Then verify silent-fail behavior with a deliberately wrong token:

```bash
TELEGRAM_BOT_TOKEN="000000:invalid" bash -c 'echo "{\"session_id\": \"manual-4\"}" | plugins/telegram/scripts/job-done.sh; echo "exit code: $?"'
```

Expected: `exit code: 0`, no message sent, retry warnings visible on stderr.

- [ ] **Step 4: Commit**

```bash
git add plugins/telegram/scripts/tests/run_all.sh
git commit -m "test(telegram): add full test-suite runner for plugins/telegram"
```

---

### Task 6: Version bump

**Files:**
- Modify: `plugins/telegram/.claude-plugin/plugin.json`

**Interfaces:** none.

- [ ] **Step 1: Bump the version**

In `plugins/telegram/.claude-plugin/plugin.json`, change:

```json
  "version": "1.0.0",
```

to:

```json
  "version": "1.1.0",
```

(Minor bump: new capability — retry/timeout/validation/dedup/truncation — not a breaking change; matches this repo's convention of bumping other plugins past 1.0.0 after enhancement work, e.g. `sdd` 1.7.0, `wbs` 1.3.0.)

- [ ] **Step 2: Verify**

Run: `python3 -c "import json; print(json.load(open('plugins/telegram/.claude-plugin/plugin.json'))['version'])"`
Expected: `1.1.0`

- [ ] **Step 3: Commit**

```bash
git add plugins/telegram/.claude-plugin/plugin.json
git commit -m "fix: update telegram plugin version to 1.1.0"
```
