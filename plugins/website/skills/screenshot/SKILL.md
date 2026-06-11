---
name: screenshot
description: >
  Takes a full-page screenshot of any URL and saves it as a PNG in the current directory.
  Use this skill whenever the user gives a URL and wants a screenshot, asks to "capture",
  "snapshot", or "screenshot" a webpage, wants to save a page as an image, or needs a
  reference image of a live website. Also trigger when the user says things like
  "take a screenshot of", "capture this page", "save this URL as PNG", or just pastes
  a URL and asks for an image. This skill handles the full workflow: launching headless
  Chrome, rendering the complete page (not just the visible portion), and saving the result.
---

## What this skill does

Renders a URL in headless Chrome and captures the **entire page** — equivalent to GoFullPage
in Chrome. Saves the result as a PNG file in the current working directory.

## How to run

```bash
node <SKILL_PATH>/scripts/screenshot.js <url> [output-filename.png]
```

- `<SKILL_PATH>` — the directory where this skill is installed (resolve via the active skill path)
- `<url>` — the full URL including `https://`
- `[output-filename.png]` — optional; defaults to a sanitized version of the URL (e.g. `example-com.png`)

**First run**: the script auto-installs `puppeteer-core` (~5MB) into the skill directory. This
takes ~15 seconds and only happens once.

## Workflow

1. Identify the target URL from the user's message.
2. Determine the output filename:
   - Use what the user specified, or
   - Default: sanitized URL slug + `.png` (e.g. `https://example.com/pricing` → `example-com-pricing.png`)
3. Run the script.
4. Report the saved path and file size to the user.

## Options

| Flag | Default | Description |
|------|---------|-------------|
| output filename | URL-based | Pass as second argument to override |
| viewport | 1440×900 | Hardcoded — full-page capture ignores height |

## Notes

- Uses Chrome at `/usr/bin/google-chrome` (already installed).
- `fullPage: true` — scrolls and stitches the entire page, not just the viewport.
- Waits for `networkidle2` before capturing, so dynamic content loads first.
- Output path is always relative to **cwd** (the directory Claude was invoked from), not the skill directory.
