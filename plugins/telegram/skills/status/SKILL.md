---
name: status
description: Show the current state of Telegram hook notifications without changing it. Use when the user says "notification status", "are notifications enabled", or invokes /telegram:status.
---

# Telegram — Notification Status

Reports whether Telegram notifications are currently enabled or disabled, without making any changes.

## Process

```bash
[ -f "$HOME/.claude/.notifications-disabled" ] && echo "DISABLED" || echo "ENABLED"
```

## Response format

Reply in one line:

> Telegram notifications are currently **ENABLED** (or **DISABLED**).
