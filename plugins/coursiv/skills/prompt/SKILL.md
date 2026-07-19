---
name: prompt
description: Converts a pair of screenshots from a Coursiv.io fill-in-the-blank prompt exercise (one showing the incomplete prompt with its placeholder options, one showing the completed prompt plus the AI tool's response) into a clean, copy/paste-ready Markdown block. Use this skill whenever the user gives two image paths from a Coursiv "complete the prompt" exercise and asks to turn them into Markdown, or invokes `/coursiv:prompt`. Trigger it even if they just paste two `.png` paths from a Coursiv lesson without spelling out the format they want — that's exactly this skill's job.
---

# Coursiv Prompt Exercise → Markdown

Convert a pair of screenshots from a Coursiv.io "complete the prompt" exercise into a clean Markdown block, ready to paste into notes or an exercise bank.

## Input

Two `.png` files, from the same exercise:
- one shows the exercise's **initial state**: the title, the instruction, an incomplete prompt with bracketed placeholders like `[tone]` or `[command]`, and a tray of answer options to fill them in with.
- one shows the exercise's **completed state**: the same prompt with the options already filled in, sent to an AI tool (Gemini, etc.), followed by that tool's response.

Don't assume which argument is which based on order or on filename — some are named with a trailing `q`/`a` (`400pq.png` / `400pa.png`) but that convention won't always hold. Instead, read both images and tell them apart by what's actually on screen: the one with visible bracketed placeholders and a row of option chips is the initial state; the one with a chat bubble showing a fully-written prompt followed by an AI response is the completed state.

### Resolving the file paths

Apply this to each of the two images independently — one might be given as an explicit path while the other is just a bare filename:

If given an explicit path (absolute, or relative to a location that clearly exists), just use it as given.

If given a bare filename with no path and it doesn't resolve relative to the current directory, don't give up — this user drops screenshots into their Obsidian inbox before asking for them to be processed. Look for the file in `/Users/lairimia/Obsidian/SecondBrain/0_Inbox` (the `0_Inbox` folder of their "SecondBrain" Obsidian vault) before concluding it doesn't exist.

If either file isn't found in either place, say so clearly — name both locations you checked, and which of the two files is missing — rather than guessing at a path or silently producing partial output.

Read both images directly once located (they're normal image files, so a plain `Read` on each path works).

### Cleaning up the inbox

For each image that lives inside `0_Inbox` — whether given as an explicit path pointing there, or found there via the fallback above — delete that file once you've successfully produced the Markdown output. That folder is a drop point for screenshots waiting to be processed, not permanent storage. Only delete after the transcription actually succeeded, and only the files that actually came from `0_Inbox` — leave alone any image given via an explicit path elsewhere (e.g. the current directory), since that's not inbox clutter.

## Output format

Output ONLY the Markdown block below — no preamble, no closing remarks, no extra explanation, no emoji. Just the block itself, so it can be copy/pasted straight into a note.

```markdown
#### <Exercise title>
<Exercise instruction>
```text
<Initial prompt, placeholders exactly as shown, e.g. [tone], [audience], [command], [information]>

<option 1> | <option 2> | <option 3>
```

##### Final prompt
```text
<Completed prompt, exactly as shown in the completed-state screenshot>
```

##### AI Response
```text
<The AI tool's response, transcribed from the completed-state screenshot>
```
```

Blank line placement, same discipline as the rest of this plugin's skills: a heading (or a fence opening) is always immediately followed by its own content on the next line, no gap — a blank line only ever separates one section from the next (before `##### Final prompt`, before `##### AI Response`, and inside the first block between the placeholder prompt and the options row). Don't add a blank line after the title, the instruction, or right after any of the three headings out of habit.

### Title and instruction
Transcribe both exactly as they appear in the initial-state screenshot — same wording, same punctuation. These sit above the mocked-up "Gemini" (or other tool) chat panel in that screenshot.

### The incomplete prompt and its options
Inside the first `text` block:
- Transcribe the prompt exactly as shown, including every placeholder in its bracketed form (`[tone]`, `[materials list]`, `[command]`, etc.) — don't fill them in here, and don't rename them.
- On the next line (separated by one blank line within the same `text` block), list every option chip from the tray at the bottom, in the order they appear on screen, separated by ` | `. Don't try to match each option to the placeholder it's meant to fill — that pairing isn't shown in this block; just preserve the visual left-to-right (then top-to-bottom) order of the option tray.

### Final prompt
Transcribe the fully completed prompt exactly as it appears in the completed-state screenshot's chat bubble — this is the "before" prompt with every placeholder replaced by its chosen option, wired together the same way the tool actually received it. Always wrap it in its own ` ```text ` fence.

### AI Response
Transcribe the AI tool's response as faithfully as possible:
- Preserve paragraphs, headings, numbering, bullets, quotation marks, and the original wording — don't correct grammar, punctuation, or style, unless a line break is obviously just a layout artifact splitting one sentence in two (join those back into one line; keep separate lines only for an actual new paragraph, heading, list item, or other real visual break).
- Don't invent text that isn't visible — if the response is cut off in the screenshot, transcribe only the visible part.
- If the response is only an image or a generated visual artifact with no readable text, write `[AI generated image]` or `[AI generated artifact]` (whichever fits what's shown) instead of transcribing anything.
- Leave out interface chrome: success labels like "Amazing!", "Continue" buttons, icons, the tool's name badge, platform feedback banners, and navigation elements. None of that is part of the response itself.

## Ignore all UI chrome

Same principle as the rest of this plugin: callout labels, buttons, icons, progress indicators, colors, and decorative elements are rendering details of the platform, not part of the exercise — never transcribe them into the output.

## Example

Given an initial-state screenshot titled "Improve the Message" with instruction "Adjust the tone of this feedback to sound more supportive," a prompt with `[tone]`, `[issue]`, `[information]` placeholders, and option chips "key details", "unclear", "supportive" (in that screen order) — and a completed-state screenshot showing the filled-in prompt and the AI's three rewrite suggestions — the output would be:

```markdown
#### Improve the Message
Adjust the tone of this feedback to sound more supportive.
```text
Rewrite the note in a more [tone] way: "Your report needs revision. Some areas are [issue] and missing [information]."

key details | unclear | supportive
```

##### Final prompt
```text
Rewrite the note in a more supportive way: "Your report needs revision. Some areas are unclear and missing key details."
```

##### AI Response
```text
Here are a few ways to rewrite that note more supportively, depending on the context:

Option 1: Focusing on Potential and Next Steps
"Thank you for submitting your report. This draft has a strong foundation, and with a focused revision, we can really enhance its impact. Let's sharpen a few key areas and ensure all critical details are present before finalizing."

Option 2: Direct and Encouraging
"I've reviewed your report. It's a great starting point! To make it shine, I'd recommend clarifying a few sections and incorporating some additional detail to strengthen the overall argument. Let me know when you'd like to chat about specifics."

Option 3: Gentle and Collaborative
"This is a solid first draft. As you move toward the next version, please focus on expanding the clarity in a few specific areas and ensuring all the essential data points are clearly addressed. Happy to review the updated sections!"
```
```

Note the option list keeps the screenshot's visual order ("key details | unclear | supportive"), even though the order they get plugged into the final prompt is different ("supportive", then "unclear", then "key details").
