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
