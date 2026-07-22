---
name: cleanup
description: Prepares a clipped Coursiv lesson note (under Clippings/<course>/*.md in the user's Obsidian vault) for standalone offline use — strips the YAML frontmatter, generates a Quizblock quiz from the lesson content following Clippings/quiz_course.md, and embeds every remote lesson image as base64 so the note needs no internet access. Use this whenever the user asks to "clean up", "process", "finalize", or "prep" a Coursiv/clipped lesson note, wants a quiz added to a Clippings note, or wants images in a note made offline-available/self-contained, or invokes `/coursiv:cleanup`. Also use if the user names a specific lesson file under Clippings and asks for frontmatter removal, quiz generation, or image embedding — even if they only ask for one of the three, since this skill's script safely handles whichever apply.
---

# Coursiv Note Cleanup

Turns a raw Coursiv lesson clipping into a self-contained, quizzed Obsidian
note. Three fixed steps, run on one note at a time:

1. Strip the YAML frontmatter (the `---...---` block at the top).
2. Generate a quiz from the lesson content, following the rules in
   `Clippings/quiz_course.md`, appended under a `## Quiz` heading.
3. Replace every remote image link with an inline base64 `data:` URI, so
   the note works with zero internet access.

## Why this is scripted instead of done by hand

The first time this was done manually, two things bit us:

- **The file gets huge.** A lesson with 4-5 images can balloon past
  400 KB once base64-encoded — several times over most tools' safe
  read/edit size. Reading the whole file back into the conversation after
  embedding is what causes token-limit errors. Lessons with a dozen
  full-resolution screenshots have hit 5MB+ and stalled Obsidian's editor
  entirely, so the script downscales images to a max width of 1200px and
  re-encodes them as JPEG (quality 65) before embedding — GIFs are left
  untouched to preserve animation, and if Pillow isn't installed it falls
  back to embedding the original bytes uncompressed.
- **File extensions lie.** Coursiv serves some images as `.jpg` that are
  actually PNG under the hood. Guessing the MIME type from the URL
  produces a note that Obsidian may fail to render.

`<SKILL_PATH>/scripts/process_note.py` handles both: it edits the file in
place via plain file I/O (never loads it into your context), and sniffs
the real image format from the downloaded bytes' magic number, not the URL.

Quiz *content* generation is the one part that genuinely needs an LLM
(it has to read and understand the lesson) — that step is yours to do,
guided by `Clippings/quiz_course.md`.

## Steps

### 1. Run the prep script

```bash
python3 <SKILL_PATH>/scripts/process_note.py prep "Clippings/<course>/<lesson>.md"
```

Run this from the vault root (`/Users/lairimia/Obsidian/SecondBrain`). It
will, in one pass:
- remove the frontmatter block if present
- download every `![...](http...)` image link, sniff its real content
  type, base64-encode it, and replace the link with a `data:` URI inline
  (downloads happen in a throwaway temp dir that's cleaned up automatically)
- make sure a `## Quiz` heading exists at the end of the file (adding one
  if it's missing; leaving it alone if it's already there, even if a
  previous run left it empty)

It prints a short report: whether frontmatter was found, how many images
were embedded, and whether any image failed to download (report failures
to the user rather than silently leaving the old link — a failed download
means that image will need a manual look).

### 2. Generate the quiz

Read `Clippings/quiz_course.md` — it is the actual, authoritative spec for
question count, format, difficulty mix, and language. Don't paraphrase it
from memory; the exact Quizblock syntax (` ```quiz `, `[ ]`/`[c]`, one
correct answer, explanation after a blank line) needs to match exactly or
the Obsidian Quizblock plugin won't render it.

To gauge how many questions to write, get a rough word count of the
lesson body (excluding the now-embedded base64 image data, since that
isn't lesson text):

```bash
python3 -c "
import re
text = open('Clippings/<course>/<lesson>.md', encoding='utf-8').read()
text = re.sub(r'data:image/[a-z]+;base64,[A-Za-z0-9+/=]+', '[IMG]', text)
print(len(text.split()), 'words')
"
```

Write the quiz blocks to a small file in your scratch directory (not in
the vault), then append it to the note with a plain file append —
**do not** open the note with a file-editing tool at this point, since it
now contains the large embedded images:

```bash
cat /path/to/scratch/quiz.md >> "Clippings/<course>/<lesson>.md"
```

### 3. Verify

```bash
python3 <SKILL_PATH>/scripts/process_note.py verify "Clippings/<course>/<lesson>.md" --expected-images <N>
```

`<N>` is the number of distinct image URLs the note originally had (note
it before step 1, since after embedding you can't easily tell how many
there were just by reading the file). This checks: no frontmatter left,
no remote image links left, the embedded image count matches what you
expect, and at least one `​```quiz` block exists. If it fails, fix the
specific thing it flags — don't re-run step 1 blindly, since that would
re-download and re-embed images that are already inline as data URIs
(the image regex only matches `http(s)://` links, so a second `prep` run
is actually safe/idempotent, but there's no reason to redo the network
calls if only the quiz step failed).

### 4. Clean up

Delete any scratch files you created for the quiz draft. The script
already cleans up its own image download temp dir automatically.

## Notes for repeat use

- This is designed to run once per lesson note, on demand, from the user
  naming a specific file. It does not batch-process a whole course folder
  by default — if the user wants that, loop step 1-3 over each `.md` file
  in the course folder, but confirm with them first since quiz generation
  for a whole course is a fair amount of work per file.
- If a note has already been processed (no frontmatter, images already
  `data:` URIs, quiz already populated), running `prep` again is harmless
  — there's nothing left for it to do. Check with `verify` first if
  you're unsure whether a note needs (re)processing.
- The `Clippings/quiz_course.md` path is assumed relative to the vault
  root (`/Users/lairimia/Obsidian/SecondBrain`), matching this vault's
  layout. If a different vault organizes clippings differently, ask the
  user where the quiz rules file lives.
