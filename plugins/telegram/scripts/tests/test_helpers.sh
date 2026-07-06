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
