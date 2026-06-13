---
name: telegram
description: Toggle Telegram hook notifications on or off by creating/removing ~/.claude/.notifications-disabled. Use when the user says "disable notifications", "turn off telegram", "enable notifications", "notify on", "notify off", or invokes /notify:telegram.
---

# Telegram — Toggle Telegram Notifications

Toggles Telegram notifications sent by the Claude Code hook scripts (`job-done.sh` and `notify-waiting.sh`). The state is persisted in `~/.claude/.notifications-disabled`.

## Invocation forms

- `/notify:telegram` — toggle current state
- `/notify:telegram on` — enable notifications
- `/notify:telegram off` — disable notifications
- `/notify:telegram status` — show current state without changing it

## Process

Read the argument (if any) from the invocation, then run the matching Bash command below. Report the result clearly.

### Toggle (no argument)

```bash
FLAG="$HOME/.claude/.notifications-disabled"
if [ -f "$FLAG" ]; then
  rm "$FLAG"
  echo "Notifications ENABLED"
else
  touch "$FLAG"
  echo "Notifications DISABLED"
fi
```

### On

```bash
rm -f "$HOME/.claude/.notifications-disabled" && echo "Notifications ENABLED"
```

### Off

```bash
touch "$HOME/.claude/.notifications-disabled" && echo "Notifications DISABLED"
```

### Status

```bash
[ -f "$HOME/.claude/.notifications-disabled" ] && echo "DISABLED" || echo "ENABLED"
```

## Response format

Reply in one line:

> Telegram notifications are now **ENABLED** (or **DISABLED**).
