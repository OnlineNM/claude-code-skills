---
name: design-brainstorm
description: Collaborative spec creation via structured brainstorming — enters plan-mode, runs a full brainstorming interview (one question at a time, 2-3 approaches with trade-offs, optional visual companion), and produces an approved spec document. Stops before implementation planning or any code. Use when user says "spec me", "spec this out", "help me spec", or wants to explore and define a feature before planning implementation.
---

# Spec-Me — Collaborative Spec Creation

Produces a hardened spec through collaborative brainstorming. Stops after the spec is written and user-approved — does NOT proceed to implementation planning or code.

## Model & Thinking

Use **Claude Sonnet** (`claude-sonnet`) with **high thinking effort** (`ultrathink`) for all reasoning in this skill.

## Language

Conduct all dialogue with the user — questions, proposed approaches, confirmations, status updates — exclusively in Romanian, regardless of the language the project/feature description was written in.

All deliverables this skill writes (`docs/<idea-slug>-SESSION.md`, `docs/<idea-slug>-DESIGN.md`) must always be written in English, independent of the Romanian dialogue above. Internal reasoning also stays in English. When a decision reached in Romanian dialogue is captured in a deliverable, translate it into English rather than copying the Romanian wording verbatim.

## Dialog Log

Maintain `docs/<idea-slug>-DIALOG.md` throughout the session — a verbatim, human-readable record of every question asked, the user's answer, the approaches proposed, and the decisions reached. This file is an explicit exception to the English-deliverables rule above: it exists to document the actual Romanian dialogue, so its content stays in Romanian, matching what was really said.

Creation is handled by ⛔ CHECKPOINT 2, alongside `SESSION.md`. Use this format — one heading per topic, one paragraph per question/answer pair:

```markdown
# Dialog: <Idea Name>
Început: <YYYY-MM-DD>

## <Subiect — ex. "Ipoteze", "Abordarea aleasă", "Secțiunea Arhitectură">

**Întrebare:** <întrebarea pusă>
**Răspuns:** <răspunsul utilizatorului>

**Decizie:** <ce s-a stabilit, dacă e cazul>

---
```

Because Step 4 delegates the actual interview to `superpowers:brainstorming`, pass it an additional override (below) instructing it to append to this file as it goes — it cannot know about `DIALOG.md` otherwise.

## Persistence

Maintain `docs/<idea-slug>-SESSION.md` throughout the session. Creation is handled by ⛔ CHECKPOINT 2 — this section describes upkeep only.

**During the session:** update `Decisions Reached` and `Open Questions` after each major brainstorming checkpoint (approach chosen, design section approved, etc.) — not necessarily after every message.

**When the spec concludes:** append `## Final Spec Path: docs/<idea-slug>-DESIGN.md` to the session file.

## Interaction Style

Where a reasonable default can be inferred from context already gathered, propose it and ask for confirmation or correction, instead of asking an open question. State the default plainly, e.g.: "Default: <X>. Confirm or tell me what to change." Reserve fully open questions for inputs with no inferable default (e.g. the raw idea description, the problem statement, or the first question of an interview before any context exists). This does not relax any existing explicit-confirmation requirement: a default still requires a clear yes or an explicit alternative choice from the user — passive agreement ("sounds good", "whatever you think") is still rejected, and the same standard applies wherever this style is used.

## Before Starting

Tell the user: *"Please run `/clear` first to start with a clean context, then re-invoke this skill."*
If the user has already cleared, proceed.

## Process

### Step 1 — Git dirty-state check
Run `git status`. If there are any uncommitted, unstaged, or untracked files, tell the user to commit or stash changes before proceeding. Do NOT continue.

### Step 2 — Enter plan-mode
Call `EnterPlanMode` immediately. All work happens in plan-mode to prevent accidental implementation.

### Step 3 — Identify idea-slug and branch strategy

#### ⛔ CHECKPOINT 1 — Slug approval (MANDATORY, do not skip)

1. From the user's description, derive `<idea-slug>` using these rules:
   - Lowercase, kebab-case
   - Only `a-z`, `0-9`, `-`
   - Replace spaces and punctuation with `-`
   - Collapse multiple `-` into one
   - Trim `-` from start and end
   - Maximum 40 characters
   
   Propose the slug to the user and **wait for explicit confirmation before continuing**. Do NOT proceed until the user approves or corrects it.

#### ⛔ CHECKPOINT 2 — Session file (MANDATORY, do not skip)

Immediately after the slug is confirmed, create `docs/<idea-slug>-SESSION.md`. Do this **now** — before the branch question, before brainstorming, before anything else. Do not defer or skip this because the session feels "short" or "simple": short sessions still get interrupted by context compaction.

```markdown
# Spec: <Idea Name>
Started: <YYYY-MM-DD>

## Summary
<one-paragraph description of what's being specced>

## Decisions Reached
<!-- updated at each brainstorming checkpoint -->

## Open Questions
<!-- updated as new questions surface -->
```

If the file already exists, read it and resume — skip decisions already settled.

Also create `docs/<idea-slug>-DIALOG.md` at this point (see "Dialog Log" section above for format). If it already exists, resume appending to it instead of overwriting.

#### ⛔ CHECKPOINT 3 — Branch strategy (MANDATORY, do not skip)

2. Present exactly these three options and ask the user to choose one — do not reduce to two:
   - **1. main** — commit directly to the current branch
   - **2. branch** — create and switch to `feature/<idea-slug>`
   - **3. worktree** — create a git worktree at `../<idea-slug>` on branch `feature/<idea-slug>` (isolated workspace, recommended for longer specs)
   
   After the user picks, invoke `superpowers:using-git-worktrees` if option 3 was chosen.
3. Set up the chosen environment before proceeding.

### Step 4 — Run brainstorming

**Before brainstorming**, check `docs/` for upstream artifacts from this slug:
1. If `docs/<slug>-IDEATE.md` exists: announce *"Found `docs/<slug>-IDEATE.md` — using it as the starting point for brainstorming."* Start brainstorming from its content instead of the raw user description.
2. Else if `docs/<slug>-INTENT.md` exists: announce *"Found `docs/<slug>-INTENT.md` — using it as the starting point for brainstorming."* Start brainstorming from its content instead of the raw user description.
3. If neither exists: start brainstorming from the user's raw description (current behavior).

**Before invoking brainstorming**, surface all implicit assumptions the user has not stated:

```
ASSUMPTIONS I'M MAKING:
1. [assumption about stack / tech]
2. [assumption about audience]
3. [assumption about constraints or scope]
→ Correct me now or I'll proceed with these.
```

Do not begin brainstorming until the user explicitly confirms or corrects the list. Append this exchange (the assumptions list and the user's confirmation/corrections) to `docs/<idea-slug>-DIALOG.md`.

Invoke `superpowers:brainstorming` and follow it exactly, with **four overrides**:

> **OVERRIDE — dialog log:** After each clarifying question is answered, after each approach/direction the user picks, and after each design section is approved, append an entry to `docs/<idea-slug>-DIALOG.md` (format defined in the invoking skill's "Dialog Log" section) recording the question/option presented and the user's answer/choice. Do this incrementally as it happens — do not wait until the end to batch-write it.

> **OVERRIDE — terminal state:** The final step of brainstorming normally transitions to `writing-plans`. Do NOT do this. The terminal state for spec-me is the user approving the written spec document. Stop there.

> **OVERRIDE — success criteria:** Whenever the user describes a vague objective (e.g. "make it faster", "improve UX"), reframe it as concrete, measurable success criteria before writing a spec section:
>
> ```
> REQUIREMENT: "Make it faster"
>
> REFRAMED SUCCESS CRITERIA:
> - [specific measurable condition, e.g. "LCP < 2.5s on 4G"]
> - [specific measurable condition]
> → Are these the right targets?
> ```
>
> Do not write a spec section for an objective that cannot be directly verified.

> **OVERRIDE — spec writing:** When the spec is ready to be written:
> 1. Write it directly to `docs/<idea-slug>-DESIGN.md` without displaying its full content in the console. Just confirm the path.
> 2. Tell the user: *"Spec written to `docs/<idea-slug>-DESIGN.md`. Please review it and let me know if you have any changes or if you approve."*
> 3. If the user provides feedback, update the file accordingly and ask again.
> 4. When the user explicitly approves, proceed to Step 5.

> **OVERRIDE — default selection:** When presenting 2-3 approaches, mark one as "(Recommended)" with a one-line reason, consistent with this project's `AskUserQuestion`-style default-first convention.

Follow every other brainstorming step as written: explore project context, offer visual companion if applicable, ask clarifying questions one at a time, propose 2-3 approaches, present design sections, run the spec self-review.

### Step 5 — Commit and confirm stop
After the user approves the spec, propose a git commit — list the files to be staged and ask for confirmation:
- `docs/<idea-slug>-DESIGN.md`
- `docs/<idea-slug>-SESSION.md` (if it exists)
- `docs/<idea-slug>-DIALOG.md` (if it exists)

On confirmation, commit with message `docs: <idea-slug> spec approved`. Do NOT push.

Then output this summary:

```
Title:     <feature title>
Slug:      <idea-slug>
Mode:      Branch | Worktree | Main
Branch:    <branch_name>        (omit if Main)
Worktree:  <worktree_path>      (omit unless Worktree)
Spec file: docs/<idea-slug>-DESIGN.md
```

#### Next step recommendation

Before pointing the user to implementation planning, assess whether the finished `docs/<idea-slug>-DESIGN.md` describes one cohesive unit of work or would benefit from being broken into independently shippable slices first:

- **Recommend `/sdd:plan`** (the common case) when the spec describes a single vertical slice — even a multi-step feature — that one TDD plan can carry end-to-end and ship as one PR.
- **Recommend `/sdd:prd`** instead when the spec itself describes 2+ independently shippable, user-visible behaviors — distinct user journeys, phases the spec already calls out separately, or subsystems that don't share a single code path. `/sdd:prd` breaks it into vertical-slice issues, each of which then gets its own `/sdd:plan` pass.

State the recommendation as a default with a one-line reason, and let the user pick the other path if they disagree (per the Language section above, deliver this message in Romanian):

> *"<brief reason, e.g. 'This spec describes a single flow — one implementation plan can cover it end-to-end.'> I recommend `/sdd:plan` as the next step, in a new session (after `/clear`). Do you want to continue with that, or would you rather go through `/sdd:prd` first to break it into separate issues?"*

Do NOT invoke either skill automatically — wait for the user's choice. Append the recommendation and the user's choice to `docs/<idea-slug>-DIALOG.md`.

## Output

- `docs/<idea-slug>-SESSION.md` — persistent session context
- `docs/<idea-slug>-DIALOG.md` — verbatim record of questions asked and decisions made (Romanian)
- `docs/<idea-slug>-DESIGN.md` — final spec, committed to git

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "This is simple, I don't need a spec" | Simple tasks don't need long specs, but they still need acceptance criteria. A two-line spec is fine. |
| "I'll write the spec after I code it" | That's documentation, not specification. The spec's value is forcing clarity before code. |
| "Requirements will change anyway" | That's why the spec is a living document. An outdated spec is still better than no spec. |
| "The user knows what they want" | Even clear requests have implicit assumptions. The spec surfaces those assumptions. |

## Hard Rules

- Do NOT invoke `writing-plans`, `executing-plans`, or any implementation skill.
- Do NOT write any code.
- Do NOT suggest next steps beyond pointing to `writing-plans` as the user's choice.
