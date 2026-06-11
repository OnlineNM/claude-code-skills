---
name: css
description: >
  Extracts CSS styles from a live webpage and saves them to a file — equivalent to
  right-click → Inspect → Copy styles in Chrome DevTools. Use this skill whenever the user
  wants to extract styles from a URL, needs CSS from a live page for design recreation,
  asks to "copy styles", "get the CSS", "extract styles from this site", or is about to
  start a /design-recreation task and needs the source styles first. Also trigger when the
  user pastes a URL and mentions styles, colors, fonts, or design tokens.
---

## What this skill does

Loads a URL in headless Chrome and extracts:
1. **CSS custom properties** (design tokens like `--color-primary`, `--font-sans`) from all stylesheets
2. **Computed styles** for the target element — identical to what Chrome DevTools "Copy styles" gives you

Saves everything to a `.css` file ready to hand to `/design-recreation`.

## How to run

```bash
node <SKILL_PATH>/scripts/extract-styles.js <url> [selector] [output.css]
```

- `<SKILL_PATH>` — the directory where this skill is installed
- `<url>` — the full URL including `https://`
- `[selector]` — CSS selector for the element to extract (default: `body`)
- `[output.css]` — optional output filename (default: URL-based slug + selector + `.css`)

**First run**: auto-installs `puppeteer-core` (~5MB) into the skill directory. Takes ~15 seconds, only happens once.

## Workflow

1. Identify the target URL from the user's message.
2. Determine the selector (default `body` unless the user specifies another element).
3. Determine the output filename (or let it default).
4. Run the script.
5. Report the saved path and counts (custom properties, computed styles) to the user.
6. If this is for a `/design-recreation` task, mention that the file is ready to pass as context.

## Output format

```css
/* CSS Custom Properties */
:root {
  --color-background: #ffffff;
  --color-primary: #3b82f6;
  --font-sans: Inter, system-ui, sans-serif;
}

/* Computed styles for: body */
/* Source: https://example.com */
body {
  background-color: rgb(255, 255, 255);
  color: rgb(17, 24, 39);
  font-family: Inter, system-ui, sans-serif;
  font-size: 16px;
  ...
}
```

## Notes

- Cross-origin stylesheets (CDN-hosted) may not expose custom properties — this is a browser security restriction, not a bug.
- Uses `networkidle2` + 800ms delay so dynamic content (fonts, JS-applied classes) settles before extraction.
- Computed styles reflect the fully resolved values after all CSS cascade, inheritance, and JS mutations — the same values you'd see in DevTools.
