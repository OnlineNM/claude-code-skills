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
