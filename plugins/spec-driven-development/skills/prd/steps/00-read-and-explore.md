# Step 00 — Read Spec and Explore Codebase

**Reads:** The SPEC.md path passed at invocation.

**Does:**

### Read the spec

Read the file at the provided path. Extract `<idea-slug>` from the filename:
- `docs/auth-forms-SPEC.md` → `idea-slug` = `auth-forms`
- `docs/youtube-funnel-SPEC.md` → `idea-slug` = `youtube-funnel`

If the file does not exist, stop and tell the user.

### Explore the codebase

Explore the repo to understand current state. Use the project's domain glossary vocabulary throughout. Respect any ADRs in the area being touched.

**Stop condition:** SPEC.md read, codebase explored.

**Hands off:** `<idea-slug>`, SPEC.md content, and codebase context to `01-seams.md`.
