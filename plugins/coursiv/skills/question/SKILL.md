---
name: question
description: Converts a screenshot of a Coursiv.io quiz question (`.png`, usually taken after the answer has already been revealed) into a clean, copy/paste-ready Markdown block with the question, unchecked answer options, correct answer(s), and explanation. Use this skill whenever the user gives an image path and asks to turn a Coursiv quiz question into Markdown, wants a quiz screenshot transcribed, or invokes `/coursiv:question`. Trigger it even if they just paste a `.png` path from a Coursiv lesson without spelling out the format they want — that's exactly this skill's job.
---

# Coursiv Question → Markdown

Convert a single screenshot of a Coursiv.io quiz question into a clean Markdown block, ready to paste into notes or a question bank.

## Input

One `.png` file pointing to a screenshot of a quiz question. The screenshot is almost always taken *after* the user already answered — so it shows selection state (checked/unchecked) and a revealed correct-answer explanation baked into the UI. Your job is to strip all of that UI chrome away and produce the clean, reusable version of the question.

### Resolving the file path

If the user gives an explicit path (absolute, or relative to a location that clearly exists — e.g. `./tmp/5q.png`), just use it as given.

If the user gives a bare filename with no path (e.g. "convert 12q.png" or "screenshot.png") and it doesn't resolve relative to the current directory, don't give up — this user drops screenshots into their Obsidian inbox before asking for them to be processed. Look for the file in the `0_Inbox` folder of the "SecondBrain" Obsidian vault before concluding it doesn't exist.

If the file isn't found in either place, say so clearly — name both locations you checked — rather than guessing at a path or silently producing no output.

Read the image directly once you've located it (it's a normal image file, so a plain `Read` on the path works).

## How to read the answer options correctly

This is the part that's easy to get wrong, so pay close attention to the icon in front of each option — it's the only reliable signal for which options are actually correct, independent of what the user happened to click:

- **Green checkmark** → this option is correct, and the user selected it.
- **Gray checkmark** → this option is correct, but the user did *not* select it (this shows up on multi-select questions where the user got a partial match — the callout will usually say "Almost right!").
- **Red X** → this option is incorrect, regardless of whether it was selected.
- **Plain circle/checkbox with no icon** → an option the user neither selected nor that was marked either way; treat it as incorrect unless a checkmark says otherwise.

So: **every checkmark (green or gray) marks a correct option**, and everything else is incorrect. Don't infer correctness from color of the surrounding box, from "Correct answer" vs "Incorrect answer" vs "Almost right!" wording, or from which one the user clicked — use the icons.

## Output format

Output ONLY the Markdown block below — no preamble, no closing remarks, no code-fence explanation, no emoji. Just the block itself, so it can be copy/pasted straight into a note.

```markdown
#### <Question title>

<Instruction, if present>

- [ ] <Answer option 1>
- [ ] <Answer option 2>
- [ ] <Answer option 3>

##### Correct answer

- <Correct option 1>
- <Correct option 2> (only if multi-select and more than one is correct)

##### Explanation

<Explanation text, rewritten as plain prose>
```

### Question title vs. instruction
The screenshot uses visual hierarchy to distinguish these two, so use the same cue rather than guessing from wording alone: the **title** is the larger/bolder heading text, and the **instruction** (if present at all) is a second, visually lighter line right below it — even when that line is a full sentence rather than a short imperative like "Select all possible answers." Both are real and both matter: don't fold the instruction into the title just because it's a longer sentence, and don't drop the title just because the instruction happens to be the more "question-like" sentence of the two.

Transcribe both exactly as shown — same wording, same punctuation, same quoted text. Only break lines where it improves readability; don't introduce line breaks that aren't needed. If there's no second line at all, skip the instruction entirely — don't invent one.

Sometimes a quoted example (a sample prompt, a piece of sample input) sits in its own visually distinct box in the screenshot — a highlighted panel set apart from the surrounding text, rather than woven into a sentence. When that's the case, keep it visually separate in the output too: finish the title/instruction text normally, then put the quoted text on its own line right after as a Markdown blockquote (`> "..."`). Don't splice it into the preceding sentence with a colon just because they're related — match the visual structure of the screenshot.

### Answer options
List every option exactly as shown, each as an unchecked checkbox (`- [ ] ...`), in the same order as the screenshot. Never mark a checkbox as selected — the whole point of this output is a fresh, unanswered version of the question. Icons, colors, and selection state from the screenshot must not leak into this list at all.

### Correct answer
- Single-select question: exactly one bullet, the correct option's text.
- Multi-select question: one bullet per correct option (per the checkmark rule above), even if the user missed one of them.
- Don't repeat all the options here, and don't add letters/numbers unless they're part of the option text itself.

### Explanation
Take the explanation text shown under the revealed-answer callout (labeled "Correct answer", "Incorrect answer", or "Almost right!" in the UI) and rewrite it as plain prose:
- Drop the callout heading itself — it never appears in the output.
- Preserve the meaning and content exactly; don't add commentary, don't summarize further, and don't mention whether the user got it right or wrong.
- If the callout says "Incorrect answer" or "Almost right!", the explanation text underneath still just explains the concept — write it the same way you would for a "Correct answer" callout.

## Ignore all UI chrome

None of the following should ever appear in the output: the callout labels ("Correct answer" / "Incorrect answer" / "Almost right!"), buttons like "Continue", icons, progress bars, decorative illustrations, colors, selection state, or scrollbars. If the image contains any of this (it usually does), just skip past it — it's a rendering detail of the platform, not part of the question.

## Example

Given a screenshot where the question reads "Which mode makes sense for processing 200 responses quickly?" with three radio options, a green check next to "Flash mode", and an explanation callout, the output would be:

```markdown
#### Which mode makes sense for processing 200 responses quickly?

- [ ] Thinking mode
- [ ] Flash mode
- [ ] Pro mode

##### Correct answer

- Flash mode

##### Explanation

Flash mode handles volume quickly. Save Thinking and Pro modes for tasks that genuinely need deeper reasoning.
```
