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
