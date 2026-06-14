---
name: toggle
description: Toggle Telegram hook notifications (flip current state). Use when the user says "toggle notifications", "toggle telegram", or invokes /telegram:toggle.
---

# Telegram — Toggle Notifications

Flips the current state of Telegram notifications. If enabled, disables them; if disabled, enables them. The state is persisted in `~/.claude/.notifications-disabled`.

## Process

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

## Response format

Reply in one line:

> Telegram notifications are now **ENABLED** (or **DISABLED**).
