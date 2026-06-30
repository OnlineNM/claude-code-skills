# Step 00 — Read Spec and Explore Codebase

**Reads:** The DESIGN.md path passed at invocation.

**Does:**

### Read the spec

Read the file at the provided path. Extract `<idea-slug>` from the filename:
- `docs/auth-forms-DESIGN.md` → `idea-slug` = `auth-forms`
- `docs/youtube-funnel-DESIGN.md` → `idea-slug` = `youtube-funnel`

If the file does not exist, stop and tell the user.

### Explore the codebase

Explore the repo to understand current state. Use the project's domain glossary vocabulary throughout. Respect any ADRs in the area being touched.

**Stop condition:** DESIGN.md read, codebase explored.

**Hands off:** `<idea-slug>`, DESIGN.md content, and codebase context to `01-seams.md`.
