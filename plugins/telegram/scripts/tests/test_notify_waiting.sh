#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/test_helpers.sh"

export CLAUDE_PLUGIN_ROOT="$SCRIPT_DIR/../.."
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
