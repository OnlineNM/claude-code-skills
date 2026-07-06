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
