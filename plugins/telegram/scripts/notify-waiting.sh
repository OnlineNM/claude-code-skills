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
