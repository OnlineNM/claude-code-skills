# Spec: Telegram plugin — enhancements din claude-code-telegram-notifications
_Locked via brainstorming — by Claude + Laurentiu Irimia_

## Goal
Portăm în `plugins/telegram` un set de îmbunătățiri de robustețe identificate în pluginul de referință `claude-code-telegram-notifications` (adrianR84), rezolvând inclusiv un bug confirmat de dublă trimitere: `notify-waiting.sh` este legat de două evenimente hook (`Notification`, async, și `PermissionRequest`, sync), fără niciun mecanism care să știe că celălalt tocmai a trimis un mesaj pentru același moment de „aștept răspunsul tău". Rezultatul dorit: notificări Telegram mai fiabile (retry, timeout, validare, truncare) și fără duplicate, păstrând neschimbat tot ce diferențiază pozitiv pluginul nostru de referință (hook `PermissionRequest` cu detalii tool/command/file, extragere reală din transcript la `Stop`, control on/off prin skills).

## Approach

### Arhitectură
- Fișier nou `plugins/telegram/scripts/telegram-utils.sh`, sursat de `job-done.sh` și `notify-waiting.sh` imediat după `load-env.sh`.
- `load-env.sh` rămâne complet neschimbat (single-responsibility: încărcare env, o singură cale `$HOME/.claude/.env` + env vars deja exportate).
- Skill-urile `notify`/`status`/`toggle` (control flag `.notifications-disabled`) rămân neatinse.

### Constante (`telegram-utils.sh`)
```bash
MAX_MESSAGE_LENGTH=4096
CURL_CONNECT_TIMEOUT=10
CURL_MAX_TIME=10
MAX_RETRIES=3
LOCK_DIR="$HOME/.claude/telegram-locks"
LOCK_TTL=5   # secunde
```

### Mecanism de deduplicare (item 0 — prioritate maximă)
`acquire_event_lock "$session_id"`:
- Fără `session_id` cunoscut → returnează succes (nu poate deduplica, trimite normal — fail-open, nu blochează notificări legitime).
- `mkdir -p "$LOCK_DIR"`.
- Cleanup opportunist la fiecare invocare: șterge orice fișier din `LOCK_DIR` mai vechi de `LOCK_TTL` (`find ... -mmin +X -delete`), indiferent de sesiune — nu necesită proces/cron separat.
- Creare atomică a `$LOCK_DIR/${session_id}.lock` via `set -o noclobber; : > "$lock_file"`. Dacă fișierul există deja (alt eveniment a trimis recent pentru aceeași sesiune) → skip trimiterea, `exit 0`.
- TTL 5s acoperă fereastra realistă de suprapunere `Notification`↔`PermissionRequest` (unul async, unul sync, pot rula concurent) fără să blocheze un `Stop` normal ulterior în aceeași sesiune.
- Apelat de **ambele** scripturi, imediat înainte de `send_telegram_message`.
- `notify-waiting.sh` trebuie extins să extragă `session_id` din payload-ul JSON (azi nu o face) — se adaugă `data.get('session_id', '')` alături de câmpurile existente (`tool_name`, `title`, `message`) în parsarea Python deja prezentă. `job-done.sh` deja are `session_id` disponibil (folosit pentru localizarea transcriptului) — se refolosește direct.

### Funcții portate din referință (adaptate — plain text, nu MarkdownV2)
- `check_dependencies`: verifică `curl`, `python3`, `sed`, `grep`, `tr`, `wc` (extins față de referință cu `python3`, folosit deja pentru parsarea JSON). Rulează o singură dată, la începutul fiecărui script, imediat după `source telegram-utils.sh`, înainte de `load-env.sh`. Eșec → mesaj clar pe stderr + `exit 0`.
- `validate_config "$token" "$chat_id"`: regex token `^[0-9]+:[a-zA-Z0-9_-]+$`, regex chat_id `^[0-9]+$` sau `^@[a-zA-Z0-9_]+$`. Rulează după `load-env.sh` și după verificarea de prezență (non-empty) existentă, înainte de orice parsare de payload. Eșec → mesaj clar pe stderr + `exit 0` (fail silențios față de restul sesiunii Claude Code, dar cu diagnostic pentru utilizator).
- `sanitize_message "$msg" "${2:-$MAX_MESSAGE_LENGTH}"`: strip control chars (`tr -d '\000-\010\013\014\016-\037'`), truncare la limită - 3 caractere + `"..."` dacă depășește. Aplicat pe mesajul final construit, imediat înainte de trimitere.
- `send_telegram_message "$token" "$chat_id" "$message"`: până la `MAX_RETRIES` (3) încercări; `curl -s -w "%{http_code}" ... --connect-timeout 10 --max-time 10`; succes doar dacă HTTP 200 **și** body conține `"ok":true`; backoff linear (2s, 4s) între încercări; la epuizare, loghează eroare pe stderr și returnează 1 — apelantul ignoră codul de retur și face `exit 0` (comportament silent-fail păstrat identic cu azi, doar cu diagnostic mai bun).
- `escape_markdown` **nu se portează acum** — rămâne documentat ca risc viitor dacă se adaugă vreodată `parse_mode`/formatare Markdown la mesaje.

### Flux integrat (`job-done.sh` și `notify-waiting.sh`)
```
1. source load-env.sh
2. source telegram-utils.sh
3. check_dependencies || exit 0                                    [nou]
4. verifică ~/.claude/.notifications-disabled → exit 0             [neschimbat]
5. verifică TOKEN/CHAT_ID prezente (non-empty) → exit 0            [neschimbat]
6. validate_config "$TOKEN" "$CHAT_ID" || exit 0                   [nou]
7. citește payload stdin, extrage session_id                       [nou pt. notify-waiting.sh]
8. acquire_event_lock "$session_id" || exit 0                      [nou — item 0]
9. construiește mesajul (parsare transcript / tool_name)           [neschimbat]
10. sanitize_message pe mesajul final                              [nou]
11. send_telegram_message (retry+timeout+verificare HTTP)          [nou, înlocuiește curl direct]
12. exit 0                                                         [neschimbat, indiferent de rezultat]
```

## Key decisions & tradeoffs
- **Lock pe tip-eveniment per sesiune, nu hash de conținut**: mesajele `Notification` și `PermissionRequest` au format diferit, deci un hash de conținut nu ar prinde cazul real confirmat prin exploration (aceleași script, payload-uri diferite). Lock-ul per `session_id`, indiferent de conținut, acoperă exact bug-ul găsit. Tradeoff: dacă în viitor apar alte cazuri de suprapunere neanticipate cu conținut diferit dar în afara ferestrei de 5s, nu vor fi prinse — acceptat ca risc minor față de complexitatea unei soluții combinate.
- **`$HOME/.claude/telegram-locks/` în loc de `/tmp`**: consistent cu `.notifications-disabled` deja acolo; pe macOS `/tmp` nu se curăță automat între sesiuni normale, deci nu ar aduce beneficiu real față de `~/.claude/`.
- **Cleanup opportunist (la fiecare rulare) în loc de TTL doar pe lock-ul propriu**: fișierele orfane din sesiuni terminate abrupt (crash/kill) nu ar fi șterse niciodată de o verificare care se uită doar la propriul `session_id`. Cleanup opportunist costă un `find` suplimentar per invocare, dar elimină complet riscul de acumulare nelimitată, fără proces/cron separat.
- **Silent-fail păstrat (exit 0) după epuizarea retry-urilor**: consecvent cu comportamentul actual — un hook Telegram nu trebuie să afecteze sesiunea Claude Code de bază. Erorile se loghează pe stderr pentru diagnosticare, dar nu se propagă ca eșec de hook.
- **Plain text păstrat, nu MarkdownV2**: evită complexitatea `escape_markdown` acum; documentat explicit ca risc viitor dacă se adaugă formatare.
- **`telegram-utils.sh` separat de `load-env.sh`**: respectă single-responsibility (încărcare env vs. trimitere/validare mesaj), minimizează diff-ul față de fișierele existente, mirror direct pe structura dovedită din pluginul de referință.

## Risks / open questions
- `acquire_event_lock` este fail-open când `session_id` lipsește din payload (nu ar trebui să se întâmple în practică, dar dacă Claude Code schimbă formatul payload-ului, dedup-ul ar înceta silențios să funcționeze fără avertisment vizibil).
- TTL de 5s e o estimare rezonabilă pe baza ferestrei observate în hook-uri; dacă latența reală dintre `Notification` și `PermissionRequest` variază semnificativ (ex. sub load), valoarea ar putea necesita ajustare ulterioară.

## Out of scope
- Escape MarkdownV2 / `parse_mode` (item 5) — doar documentat, nu implementat.
- Căutarea `.env` în 6 locații hardcodate — respins explicit, păstrăm `load-env.sh` cu o singură cale.
- Debug logging verbos (`DEBUG=true` toggle) — respins explicit ca overkill pentru un skill intern.
- Parsare JSON cu `sed`/regex — păstrăm parsarea Python existentă, superioară.
- Orice schimbare funcțională la hook-ul `PermissionRequest`, extragerea din transcript la `Stop`, sau skill-urile `notify`/`status`/`toggle`.
