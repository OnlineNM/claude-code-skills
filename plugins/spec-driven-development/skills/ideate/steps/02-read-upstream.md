# Step 02 — Read Upstream Artifact

**Reads:** `<idea-slug>` from `01-slug-and-branch.md`; optional `docs/<slug>-INTENT.md`.

**Does:**

If an INTENT.md path was passed, read it and announce:
*"Found `docs/<slug>-INTENT.md` — starting from confirmed intent."*

Use the INTENT.md content as the seed for Phase 1.

**Stop condition:** Upstream content read (or confirmed absent).

**Hands off:** Seed content (or none) to `03-diverge.md`.
