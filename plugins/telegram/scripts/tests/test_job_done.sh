#!/usr/bin/env bash
set -uo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/test_helpers.sh"

export CLAUDE_PLUGIN_ROOT="$SCRIPT_DIR/../.."
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
