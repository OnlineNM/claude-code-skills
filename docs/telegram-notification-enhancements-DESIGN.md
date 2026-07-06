# Spec: Telegram plugin — enhancements din claude-code-telegram-notifications
_Locked via brainstorming — by Claude + Laurentiu Irimia_

## Goal
Portăm în `plugins/telegram` un set de îmbunătățiri de robustețe identificate în pluginul de referință `claude-code-telegram-notifications` (adrianR84), rezolvând inclusiv un bug confirmat de dublă trimitere: `notify-waiting.sh` este legat de două evenimente hook (`Notification`, async, și `PermissionRequest`, sync), fără niciun mecanism care să știe că celălalt tocmai a trimis un mesaj pentru același moment de „aștept răspunsul tău". Rezultatul dorit: notificări Telegram mai fiabile (retry, timeout, validare, truncare) și **eliminarea clasei de duplicate confirmate în fereastra normală de suprapunere** (evenimente „aproape simultane", ordinea din bug-ul raportat) — cu o garanție best-effort, nu matematic absolută, pentru cazul rezidual în care `PermissionRequest` sosește după ce `Notification` și-a încheiat deja fereastra de debounce (vezi „Key decisions") — păstrând neschimbat tot ce diferențiază pozitiv pluginul nostru de referință (hook `PermissionRequest` cu detalii tool/command/file, extragere reală din transcript la `Stop`, control on/off prin skills).

## Approach

### Arhitectură
- Fișier nou `plugins/telegram/scripts/telegram-utils.sh`, sursat de `job-done.sh` și `notify-waiting.sh` imediat după `load-env.sh`.
- `load-env.sh` rămâne complet neschimbat (single-responsibility: încărcare env, o singură cale `$HOME/.claude/.env` + env vars deja exportate).
- Skill-urile `notify`/`status`/`toggle` (control flag `.notifications-disabled`) rămân neatinse.

### Constante (`telegram-utils.sh`)
```bash
MAX_MESSAGE_LENGTH=4096
CURL_CONNECT_TIMEOUT=5
CURL_MAX_TIME=5
MAX_RETRIES=2
LOCK_DIR="${HOME-}/.claude/telegram-locks"   # expansiune safe sub set -u; $HOME validat runtime în check_dependencies
LOCK_TTL=5          # secunde — cât rămâne valid un lock
NOTIFICATION_DEBOUNCE=1.5   # secunde — cât așteaptă Notification înainte de a trimite, ca să lase loc unui PermissionRequest concurent
```
_(Revizuit Round 1-4.)_

### Mecanism de deduplicare (item 0 — prioritate maximă)
Aplicat **doar în `notify-waiting.sh`** (comun apelurilor `Notification` și `PermissionRequest`) — **NU** în `job-done.sh` (vezi „Key decisions").

**Politică deterministă cu claim atomic** _(corectat Round 3, făcut atomic Round 4)_: variantele anterioare aveau ferestre de cursă (check → sleep → re-check → send, cu un gap ne-atomic între verificare și trimitere unde un `PermissionRequest` concurent tot putea scăpa nedetectat). Soluția finală: **`try_claim` combină verificarea și crearea lock-ului într-o singură operație atomică** (creare de fișier cu `noclobber`, garantată atomic de kernel via `O_EXCL`), eliminând orice gap între „am verificat" și „am trimis":

- **`PermissionRequest`** (identificat prin prezența `tool_name` în payload — mecanism deja folosit de codul actual pentru formatarea mesajului, dovedit funcțional în producție, nu introduce fragilitate nouă): apelează `mark_claim "$key"` **imediat, înainte de trimitere** — spre deosebire de `try_claim`, `mark_claim` curăță întâi lock-urile expirate și **suprascrie necondiționat** fișierul de lock (mtime proaspăt), indiferent dacă exista deja unul vechi _(fix Round 5 — `try_claim` cu `noclobber` ar fi eșuat silențios dacă exista un lock expirat nesincronizat, lăsând mtime-ul vechi; un cleanup ulterior l-ar fi șters ca stale și un `Notification` de după ar fi trimis din nou, recreând bug-ul confirmat)_. Apoi trimite **necondiționat** — mesajul cu detalii tool/command/file nu e niciodată suprimat. Rulează sync, fără debounce (nu poate întârzia aprobarea utilizatorului).
- **`Notification`** (fără `tool_name`, rulează async — își poate permite o mică întârziere):
  1. `has_active_lock "$key"` → dacă da, skip imediat (optimizare: evită să mai aștepte degeaba dacă un `PermissionRequest` a trimis deja).
  2. Altfel, așteaptă `NOTIFICATION_DEBOUNCE` (1.5s) — acoperă fereastra „aproape simultan" descrisă în bug-ul original.
  3. `try_claim "$key"` — dacă reușește (a creat lock-ul primul), trimite. Dacă eșuează (lock-ul exista deja — un `PermissionRequest` l-a creat între timp), skip fără să mai trimită.
- **Garanție**: în fereastra realistă descrisă de bug (`Notification`/`PermissionRequest` „aproape simultane"), se trimite exact un mesaj, cel de `PermissionRequest` dacă există. Rămâne un risc rezidual acceptat _(reformulat Round 6 — „doar la nivel de microsecunde" era prea îngust)_: dacă `PermissionRequest` sosește oricând **după** ce `Notification` și-a încheiat deja debounce-ul și a câștigat claim-ul (nu doar la exact aceeași instrucțiune de sistem), ambele mesaje pot fi trimise — practic neglijabil, fiindcă fereastra „aproape simultan" din bug-ul original e mult mai scurtă decât debounce-ul de 1.5s; **garanția e best-effort, nu matematic absolută**.
- Claim-ul se face **înainte** de trimitere (nu după succes, cum era în Round 3) — tradeoff acceptat: dacă `PermissionRequest` claim-uiește dar apoi eșuează total la trimitere (rar, după 2 încercări interne), un `Notification` concurent rămâne suprimat deși niciun mesaj n-a ajuns la utilizator. Acceptat ca preferabil față de riscul de dublă trimitere pe bug-ul confirmat (prioritate maximă).

**Cheie de lock — hash SHA-256 complet, nu sanitizare distructivă și nu trunchiat** _(fix Round 2, ajustat Round 4 — trunchierea la 16 caractere nu avea niciun beneficiu real pentru un nume de fișier, elimină orice risc teoretic de coliziune)_: `session_id` brut se hash-uiește complet (`hash_session_id`, vezi mai jos). Dacă `session_id` e gol/lipsă, funcția tratează cazul **înainte** de hash — fail-open direct (trimite normal, loghează warning pe stderr).

**Fallback dacă `session_id` lipsește din payload-ul `Notification`**: cheia de fallback e `cwd` (directorul de lucru al sesiunii), dacă prezent în ambele payload-uri — folosirea fallback-ului se loghează explicit pe stderr (`"Telegram: dedup using cwd fallback"`) ca eventualele suprimări greșite să fie diagnosticabile ulterior _(fix Round 5)_. Acceptat ca risc rezidual documentat: dacă două sesiuni paralele rulează simultan în același director în fereastra de TTL, fallback-ul pe `cwd` le-ar putea încurca (un `PermissionRequest` din sesiunea A ar suprima un `Notification` din sesiunea B) — caz rar pentru un tool intern cu tipic o sesiune activă per director; dacă nici `cwd` nu e disponibil, dedup-ul rămâne fail-open (warning explicit).

```bash
hash_session_id() {
  local id="$1" full hash   # `hash` declarat local explicit (fix Round 6 — altfel scapă în scope-ul apelantului)
  if command -v shasum >/dev/null 2>&1; then
    full=$(printf '%s' "$id" | shasum -a 256)
  else
    full=$(printf '%s' "$id" | sha256sum)
  fi
  read -r hash _ <<< "$full"   # primul cuvânt, fără dependență de awk (fix Round 5)
  printf '%s' "$hash"
}

lock_path_for() { printf '%s/%s.lock' "$LOCK_DIR" "$(hash_session_id "$1")"; }

# Return 1 dacă directorul de lock nu poate fi pregătit (permisiuni etc.) — apelanții tratează asta ca "locking indisponibil".
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

# Notification: dacă infrastructura de lock e indisponibilă, fail-open (tratează ca "neblocat" — mai bine o notificare în plus decât una pierdută silențios).
has_active_lock() {
  cleanup_stale_locks || return 1
  [ -e "$(lock_path_for "$1")" ]
}

# Notification: creare atomică (O_EXCL via noclobber) — combină verificare + creare într-un singur pas, elimină gap-ul check-apoi-send.
# Dacă directorul de lock e indisponibil, tratează ca "am câștigat claim-ul" (fail-open — trimite oricum).
try_claim() {
  cleanup_stale_locks || return 0
  local lock_file; lock_file="$(lock_path_for "$1")"
  if ( set -o noclobber; : > "$lock_file" ) 2>/dev/null; then
    return 0
  else
    return 1
  fi
}

# PermissionRequest: curăță expirate, apoi suprascrie necondiționat (mtime proaspăt) — niciodată nu blochează trimiterea.
# Returnează 1 dacă locking-ul e indisponibil (apelantul ignoră codul, dar semnalul rămâne testabil direct — fix Round 6).
mark_claim() {
  cleanup_stale_locks || { : > "$(lock_path_for "$1")" 2>/dev/null; return 1; }
  : > "$(lock_path_for "$1")" 2>/dev/null
}
```
_(Notă de implementare, non-blocantă — Round 6: `ensure_lock_dir` poate fi apelat de mai multe ori per invocare script și, dacă directorul e indisponibil, ar putea loga warning-ul de mai multe ori; acceptabil pentru diagnosticare, opțional de redus cu o variabilă „warned once" per proces la implementare.)_

### Funcții portate din referință (adaptate — plain text, nu MarkdownV2)
- `check_dependencies`: verifică `curl`, `python3`, `tr`, `stat`, `date`, `mktemp`, `chmod`, `mkdir`, `rm`, și (`shasum` SAU `sha256sum`) — lista completă a comenzilor externe folosite efectiv de `telegram-utils.sh` _(fix Round 2+3+4 — lista omitea inițial `stat`/`date`/`shasum`/`mktemp`, apoi `chmod`, apoi `mkdir`/`rm`)_. `sleep` nu mai e necesar ca dependență externă — debounce-ul folosește `python3` (vezi mai jos), deja o dependență obligatorie. Verifică și că `$HOME` e setat și non-gol aici (nu prin `${HOME:?}` la assignment de variabilă, care ar opri scriptul brusc sub `set -u` — fix Round 2/3). Rulează după `source load-env.sh`/`source telegram-utils.sh`, înainte de `validate_config`. Eșec → mesaj clar pe stderr + `exit 0`.
- Scripturile presupun **bash** explicit (shebang `#!/usr/bin/env bash`, ca și azi).
- `validate_config "$TELEGRAM_BOT_TOKEN" "$TELEGRAM_CHAT_ID"`: regex token `^[0-9]+:[a-zA-Z0-9_-]+$`; regex chat_id `^-?[0-9]+$` sau `^@[^[:space:]]+$` (verificare minimă de sanitate, nu validare completă de format Telegram). Eșec → mesaj clar pe stderr + `exit 0`.
- `sanitize_message "$msg"`: strip control chars (`tr -d '\000-\010\013\014\016-\037'` — TAB/LF/CR păstrate explicit), truncare la `MAX_MESSAGE_LENGTH - 3` caractere + `"..."` dacă depășește (pe număr de caractere, nu bytes UTF-8 — vezi „Out of scope").
- `send_telegram_message "$token" "$chat_id" "$message"`: până la `MAX_RETRIES` (2) încercări; niciodată `parse_mode`; mereu POST body form-encoded. Body-ul răspunsului se scrie într-un fișier temporar creat cu `tmp_body=$(mktemp) || { echo "Telegram: mktemp failed" >&2; return 1; }` _(fix Round 4 — eșecul lui `mktemp` era netratat)_, cu `rm -f "$tmp_body"` explicit înainte de **fiecare** `return` din funcție _(fix Round 3 — nu se mai folosește `trap ... RETURN`, care poate interfera cu alte capcane dacă funcția e apelată din contexte sursate)_. Apelul curl:
  ```bash
  if http_code=$(curl -s -o "$tmp_body" -w '%{http_code}' -X POST \
      --connect-timeout "$CURL_CONNECT_TIMEOUT" --max-time "$CURL_MAX_TIME" \
      --data-urlencode "chat_id=${chat_id}" --data-urlencode "text=${message}" \
      "https://api.telegram.org/bot${token}/sendMessage"); then
    curl_exit=0
  else
    curl_exit=$?; http_code="${http_code:-000}"
  fi
  ```
  compatibil explicit cu `set -e` (eșecul lui curl nu oprește scriptul, fiindcă e în condiția unui `if`) și păstrează codul de exit al curl pentru diagnostic _(fix Round 3)_. HTTP `000` tratat explicit ca eșec de încercare. Verificarea `"ok":true` via `python3 -c '...' "$tmp_body"` cu path-ul **pasat ca argument** (`sys.argv[1]`), nu interpolat în sursa Python _(fix Round 2, bug de quoting)_. Succes doar dacă HTTP 200 **și** verificarea Python confirmă `ok:true`. Backoff: 2s între cele 2 încercări. La epuizare, loghează eroare pe stderr, returnează 1 (testat direct, separat de `exit 0`-ul scriptului apelant).
- `escape_markdown` **nu se portează acum** — documentat ca risc viitor.

### Flux integrat

**`job-done.sh`** (neschimbat structural, doar funcțiile de trimitere sunt noi):
```
1. source load-env.sh; source telegram-utils.sh
2. check_dependencies || exit 0
3. verifică ~/.claude/.notifications-disabled → exit 0
4. verifică TOKEN/CHAT_ID prezente → exit 0
5. validate_config || exit 0
6. construiește mesajul (parsare transcript, neschimbat)
7. sanitize_message
8. send_telegram_message
9. exit 0
```

**`notify-waiting.sh`** (fluxul cu dedup):
```
1. source load-env.sh; source telegram-utils.sh
2. check_dependencies || exit 0
3. verifică ~/.claude/.notifications-disabled → exit 0
4. verifică TOKEN/CHAT_ID prezente → exit 0
5. validate_config || exit 0
6. citește payload stdin; extrage session_id (sau fallback cwd) + tool_name/title/message (ca azi)
7. construiește mesajul (parsare tool_name — ca azi) și sanitize_message
8. dacă tool_name prezent (PermissionRequest):
     mark_claim "$key"       # curăță expirate + suprascrie necondiționat, rezultat ignorat
     send_telegram_message
9. altfel (Notification):
     if has_active_lock "$key"; then exit 0; fi        # optimizare, evită așteptarea degeaba
     python3 -c 'import time,sys; time.sleep(float(sys.argv[1]))' "$NOTIFICATION_DEBOUNCE"   # debounce portabil, fără dependență de sleep fracționat
     if try_claim "$key"; then send_telegram_message; fi   # claim atomic + trimitere; dacă claim eșuează, skip
10. exit 0 (indiferent de rezultatul trimiterii)
```

### Latență maximă acceptată pe hook-uri sync
Cu `MAX_RETRIES=2`, `--connect-timeout 5`, `--max-time 5`, backoff 2s: worst-case ≈ 5+2+5 = 12s. Acceptabil pentru `PermissionRequest` (rulează sync, blochează prompt-ul de aprobare doar în scenariul rar de eșec de rețea — cazul normal de succes e aproape instant, o singură cerere) și sub timeout-ul de 30s configurat pentru `Stop`.

### Nume de variabile de mediu
Scripturile folosesc exact `TELEGRAM_BOT_TOKEN` și `TELEGRAM_CHAT_ID` (consistent cu codul actual și cu `.env`), încărcate de `load-env.sh` neschimbat.

### Plan de acceptanță / testare manuală
- Trimitere normală (succes) pentru `job-done.sh` și `notify-waiting.sh` (ambele variante de payload: `Notification` și `PermissionRequest`).
- **Pas 0, obligatoriu înainte de implementare**: confirmă din payload-uri reale (log-uri Claude Code sau documentație hook) că evenimentul `Notification` chiar conține `session_id` (sau, ca fallback definit, `cwd`) la nivel de top, la fel ca `PermissionRequest`.
- **Test de concurență real** _(adăugat Round 3 — bug-ul e o cursă, nu doar o secvență)_: lansează în paralel, ca două procese background cu același `session_id`/fixture, un apel `notify-waiting.sh` cu payload `Notification` și unul cu payload `PermissionRequest` (`bash notify-waiting.sh < notification.json & bash notify-waiting.sh < permission.json & wait`) → verifică prin log-uri/mock că se trimite exact un mesaj Telegram, cel de `PermissionRequest`.
- Ordinea `Notification` primul, `PermissionRequest` la <1.5s după → exact un mesaj trimis (`PermissionRequest`, fiindcă `Notification` reverifică lock-ul după debounce și îl găsește).
- Ordinea `PermissionRequest` primul, `Notification` imediat după → exact un mesaj trimis (`PermissionRequest`; `Notification` vede lock-ul din prima verificare, fără să mai aștepte debounce-ul).
- `has_active_lock`/`try_claim`/`mark_claim` — testate separat de comportamentul de script: apel direct al funcțiilor verifică efectul pe filesystem (fișier creat/suprascris, return code); separat, un test de script verifică efectul vizibil (mesaj trimis sau nu, `exit 0` în ambele cazuri) _(actualizat Round 5 — numele funcțiilor din draft-urile anterioare, `acquire_or_mark_lock`/`mark_event_sent`, nu mai există)_.
- Lock expirat (fișier `.lock` cu mtime > 5s în urmă) creat de un `PermissionRequest` anterior, urmat de un nou `PermissionRequest` pentru aceeași sesiune → `mark_claim` curăță lock-ul vechi și îl recreează cu mtime proaspăt (nu doar `try_claim`, care ar fi eșuat silențios pe fișierul existent) — verifică explicit acest caz, e regresia identificată în Round 5.
- Lock expirat urmat de un `Notification` nou → trimite normal, lock-ul vechi e curățat la cleanup opportunist.
- Director de lock inaccesibil (permisiuni simulate, ex. `chmod 000` pe `$LOCK_DIR` înainte de test) → verifică fail-open: mesajul tot se trimite, cu warning pe stderr.
- `PermissionRequest` care eșuează total la trimitere (Telegram jos) urmat de un `Notification` concurent → `Notification` e suprimat corect (claim-ul PermissionRequest s-a făcut înainte de trimitere), deși niciun mesaj n-a ajuns la utilizator — comportament acceptat explicit (vezi „Key decisions"), nu un bug de fix aici.
- Token/chat_id invalid (format greșit) → mesaj clar pe stderr, `exit 0`, nimic trimis.
- Eșec API Telegram cu token greșit (HTTP 401 sau `"ok":false`) testat separat de eșec de transport (curl `000`, DNS blocat/timeout) — ambele scenarii cu cele 2 încercări + backoff vizibile pe stderr, apoi `exit 0`.
- Payload cu `session_id` lipsă (și fără `cwd` utilizabil) → warning pe stderr, mesajul tot se trimite (fail-open confirmat).
- Mesaj cu newline-uri → verifică că `sanitize_message` păstrează liniile (nu le colapsează).
- Mesaj peste 4096 caractere → verifică truncare la 4093 + `"..."`.
- Path de temp file cu caracter special (ghilimea simplă) → verifică că verificarea `"ok":true` via Python nu se rupe (validează fix-ul de quoting).

## Key decisions & tradeoffs
- **Lock scope limitat la `notify-waiting.sh`, nu și `job-done.sh`** _(Round 1)_: bug-ul confirmat prin exploration e strict între `Notification` și `PermissionRequest`, ambele rulând `notify-waiting.sh`. Extinderea la `Stop`/`job-done.sh` ar risca suprimarea unei notificări de finalizare legitime — acceptat ca residual risk (Enhancements.md menționează suprapunerea Stop/Notification doar ca alternativă posibilă, nu ca bug confirmat).
- **Politică deterministă cu claim atomic (`try_claim`), nu check-then-act** _(Round 1 → 3 → atomicizată Round 4)_: variantele anterioare aveau fie un lock nedeterminist (Round 1, permitea dubla trimitere), fie un check-wait-recheck-send cu gap ne-atomic între verificare și trimitere (Round 3, tot vulnerabil la o cursă strânsă). Soluția finală combină verificare+creare într-o singură operație atomică (`noclobber`/`O_EXCL`): `PermissionRequest` claim-uiește și trimite mereu necondiționat (nu e niciodată suprimat); `Notification` așteaptă 1.5s apoi încearcă claim-ul — dacă reușește, trimite; dacă nu, sare. Rămâne un risc rezidual dacă `PermissionRequest` sosește după ce debounce-ul lui `Notification` s-a încheiat deja (documentat explicit ca best-effort, nu garanție matematică absolută), acceptabil pentru un tool intern.
- **Claim înainte de trimitere, nu marcare după succes** _(schimbat față de Round 3 — necesar pentru atomicitate reală, Round 4)_: tradeoff acceptat explicit, valabil simetric pentru ambele evenimente _(extins Round 5)_ — dacă `PermissionRequest` (via `mark_claim`) sau `Notification` (via `try_claim`) claim-uiește dar eșuează total la trimitere (rar, după 2 încercări), un eveniment concurent/ulterior în fereastra de TTL rămâne suprimat fără ca vreun mesaj să fi ajuns la utilizator. Preferat față de riscul de dublă trimitere pe bug-ul confirmat.
- **`mark_claim` (PermissionRequest) suprascrie necondiționat, `try_claim` (Notification) creează atomic doar dacă lipsește** _(fix Round 5)_: dacă am folosit `try_claim` și pentru `PermissionRequest`, un lock expirat nesincronizat ar fi rămas cu mtime vechi (creația eșuează silențios pe fișier existent), un cleanup ulterior l-ar fi șters ca stale, iar un `Notification` de după ar fi trimis din nou — recreând exact bug-ul confirmat. `mark_claim` evită asta prin curățare + suprascriere necondiționată.
- **Fail-open când infrastructura de lock e indisponibilă** _(fix Round 5)_: dacă `$LOCK_DIR` nu poate fi creat/securizat (permisiuni etc.), `has_active_lock`/`try_claim` tratează asta ca „neblocat" (mai bine o notificare în plus decât toate notificările suprimate silențios pe un sistem cu locking stricat) — cu un warning explicit pe stderr.
- **`$HOME/.claude/telegram-locks/` în loc de `/tmp`**: consistent cu `.notifications-disabled` deja acolo; pe macOS `/tmp` nu se curăță automat între sesiuni normale.
- **Cleanup opportunist bazat pe `stat`, nu `find -mmin`** _(fix Round 1)_: `find -mmin` are granularitate de minut, nu poate exprima un TTL de 5 secunde. Cleanup iterează fișierele `*.lock` și compară vârsta via `stat`/`date`, portabil macOS/Linux.
- **Hash SHA-256 pentru cheia de lock, nu sanitizare distructivă a `session_id`** _(fix Round 2)_: `tr -cd` ar putea coliza ID-uri diferite sau produce string gol; hash-ul evită ambele.
- **Timeouts/retries reduse (`CURL_*_TIMEOUT=5`, `MAX_RETRIES=2`, backoff 2s)** _(fix Round 1)_: valorile inițiale (10s×3 încercări + backoff 2s/4s) dădeau un worst-case de ~36s pe hook-uri sync (`PermissionRequest`, `Stop`), inacceptabil ca latență pe un prompt de aprobare. Noul worst-case (~12s) rămâne sub timeout-ul de 30s al `Stop` și e acceptabil pentru `PermissionRequest`.
- **Parsare răspuns curl via `python3`, nu `grep`** _(fix Round 1)_: body-ul salvat separat via `curl -o`, verificarea `"ok":true` prin `python3 -c "import json..."` în loc de `grep '"ok":true'`, robust la variații de formatare JSON (`"ok": true` cu spațiu, etc.) și la HTTP `000` (eroare de transport).
- **Silent-fail păstrat (exit 0) după epuizarea retry-urilor**: consecvent cu comportamentul actual. Funcțiile interne (`send_telegram_message`, `acquire_event_lock`) întorc coduri semnificative pentru testare directă, chiar dacă scriptul-apelant ignoră codul final.
- **Plain text păstrat, nu MarkdownV2**: evită complexitatea `escape_markdown` acum; documentat explicit ca risc viitor dacă se adaugă formatare. `send_telegram_message` nu trimite niciodată `parse_mode`.
- **`telegram-utils.sh` separat de `load-env.sh`**: respectă single-responsibility, minimizează diff-ul, mirror pe structura dovedită din referință.
- **`sanitize_message` cu semnătură simplă (un singur argument)** _(fix Round 1)_: elimină parametrul opțional de limită din draft-ul inițial (nefolosit — referința îl folosea doar pentru un caz specific, `notification_type`, pe care nu-l portăm).

## Risks / open questions
- Dedup-ul e fail-open când nici `session_id`, nici fallback-ul `cwd` nu sunt disponibile — loghează un warning explicit pe stderr, dar comportamentul rămâne "trimite normal, fără dedup" în acel caz.
- TTL de 5s / debounce de 1.5s sunt estimări rezonabile pe baza ferestrei "aproape simultan" descrise în bug; dacă latența reală dintre `Notification` și `PermissionRequest` variază semnificativ (ex. sub load), valorile ar putea necesita ajustare ulterioară.
- **Blocant pentru implementare** _(Round 2, fallback precizat Round 3)_: nu e confirmat din exploration că payload-ul `Notification` conține `session_id` la nivel de top. Primul pas de implementare verifică acest lucru cu payload-uri reale; fallback-ul definit e `cwd`, dacă prezent în ambele payload-uri.
- Debounce-ul de 1.5s presupune că `Notification` și `PermissionRequest` sosesc într-o fereastră scurtă; dacă în practică apar la interval mai mare (ex. >2s), dubla trimitere ar putea reapărea în acel caz rar — acceptat ca risc rezidual, nu ca bug nerezolvat al scenariului confirmat (fereastra "aproape simultan").
- Detectarea `PermissionRequest` prin prezența `tool_name` reutilizează logica deja existentă azi în `notify-waiting.sh` pentru formatarea mesajului — dacă Claude Code schimbă vreodată forma payload-ului, atât formatarea mesajului cât și rutarea dedup s-ar rupe împreună (risc pre-existent, nu unul nou introdus de acest spec).
- Truncarea `sanitize_message` numără caractere, nu bytes UTF-8 (emoji/caractere combinate pot fi tăiate la mijloc) — acceptat explicit ca limitare de produs pentru acest tool (nu o scuză de "e doar personal", ci o decizie deliberată de a nu introduce dependențe suplimentare pentru un caz marginal).
- Vizibilitatea mesajelor de stderr depinde de cum Claude Code capturează/afișează output-ul hook-urilor — comportament identic cu azi (scripturile actuale scriu deja pe stderr, ex. "Telegram credentials not set"), nu se schimbă în acest spec.
- Token-ul Telegram apare inevitabil în URL-ul cerut de Telegram Bot API (`.../bot<token>/sendMessage`) — caracteristică inerentă a API-ului, prezentă deja în codul curent și în referință; nu se schimbă în acest spec.

## Out of scope
- Escape MarkdownV2 / `parse_mode` (item 5) — doar documentat, nu implementat.
- Căutarea `.env` în 6 locații hardcodate — respins explicit, păstrăm `load-env.sh` cu o singură cale.
- Debug logging verbos (`DEBUG=true` toggle) — respins explicit ca overkill pentru un skill intern.
- Parsare JSON cu `sed`/regex — păstrăm parsarea Python existentă, superioară.
- Orice schimbare funcțională la hook-ul `PermissionRequest`, extragerea din transcript la `Stop`, sau skill-urile `notify`/`status`/`toggle` (dincolo de comportamentul diferențiat de dedup descris mai sus, care nu schimbă conținutul mesajelor).
- Dedup între `Stop` și `Notification`/`PermissionRequest` — residual risk acceptat (vezi „Key decisions"), nu prioritate maximă precum item 0 original.
- Ștergerea lock-ului imediat după trimitere reușită — se preferă simplitatea TTL-only, combinată cu bugetul de retry redus.
- Trunchiere exact-bytes UTF-8 (Python-based) pentru `sanitize_message` — decizie explicită de produs, nu doar limitare tehnică acceptată tacit.
- Rescrierea invocării `curl` pentru a evita expunerea argumentelor în `ps` (ex. `curl -K -`) — caracteristică pre-existentă în codul curent și în referință, nu o regresie introdusă de acest spec.
