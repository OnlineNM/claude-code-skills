---
name: notify
description: Enable or disable Telegram hook notifications. Use when the user says "enable notifications", "disable notifications", "notify on", "notify off", or invokes /telegram:notify on|off.
---

# Telegram — Enable/Disable Notifications

Enables or disables Telegram notifications sent by the Claude Code hook scripts (`job-done.sh` and `notify-waiting.sh`). The state is persisted in `~/.claude/.notifications-disabled`.

## Invocation forms

- `/telegram:notify on` — enable notifications
- `/telegram:notify off` — disable notifications

## Process

Read the argument from the invocation, then run the matching Bash command below.

### On

```bash
rm -f "$HOME/.claude/.notifications-disabled" && echo "Notifications ENABLED"
```

### Off

```bash
touch "$HOME/.claude/.notifications-disabled" && echo "Notifications DISABLED"
```

## Response format

Reply in one line:

> Telegram notifications are now **ENABLED** (or **DISABLED**).
