# Spec: Telegram plugin — enhancements din claude-code-telegram-notifications
Started: 2026-07-06

## Summary
Portăm în `plugins/telegram` un set de îmbunătățiri de robustețe identificate în pluginul de referință `claude-code-telegram-notifications` (adrianR84), documentate în `Enhancements.md`: deduplicare notificări succesive (bug, prioritate maximă), retry cu backoff, verificare explicită a răspunsului API, timeout pe curl, validare token/chat_id, escape MarkdownV2 (de reținut), truncare mesaj, dependency check. Explicit nu se portează: căutarea .env în 6 locații hardcodate, debug logging verbose, parsare JSON cu sed/regex.

## Decisions Reached
- Arhitectură: fișier nou `telegram-utils.sh` sursat de `job-done.sh` și `notify-waiting.sh`; `load-env.sh` neschimbat.
- Dedup (item 0): lock pe tip-eveniment per `session_id`, fișier atomic în `$HOME/.claude/telegram-locks/`, TTL 5s, cleanup opportunist la fiecare rulare.
- `send_telegram_message`: retry x3, backoff linear 2s/4s, verificare HTTP 200 + `"ok":true`, timeout curl 10s.
- `validate_config`: regex token/chat_id, eșec → exit 0 cu mesaj clar pe stderr.
- `sanitize_message`: truncare la 4096 caractere, strip control chars.
- `check_dependencies`: extins cu `python3` față de referință.
- Silent-fail păstrat (exit 0) după epuizarea retry-urilor.
- Plain text păstrat — `escape_markdown`/MarkdownV2 NU se portează acum (documentat ca risc viitor).
- PermissionRequest, extragere transcript, skill-urile notify/status/toggle — neatinse funcțional.

## Open Questions
- Ce se întâmplă dacă `session_id` lipsește din payload (fail-open pe dedup) — acceptat ca risc minor, documentat în DESIGN.md.
- TTL 5s e o estimare — poate necesita ajustare ulterioară.

## Final Spec Path: docs/telegram-notification-enhancements-DESIGN.md
