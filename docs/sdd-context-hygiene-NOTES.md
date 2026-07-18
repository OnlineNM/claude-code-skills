# Notes: SDD Context Hygiene & Reliability Fixes

Source: conversation review of `sdd:plan`, `sdd:implement`, `sdd:verify`,
`sdd:revise`, `sdd:finalize` (plugin `spec-driven-development`), cross-checked
against real session transcripts from a remote run (project `nats-msgs`,
2026-07-17) accessed via SSH at `~/.claude/projects/-home-parallels-nats-msgs/`.
Intended as raw input for `/sdd:design` before writing a formal DESIGN.md.

## Finding 0 — Initial hypothesis was wrong, but worth recording

Original concern: these skills read the PRD plus every ISSUE/PLAN/LOG file for
all issues, not just the current one, causing repeated mid-run compaction.
Transcript inspection (session `dee0d8c3`, `/sdd:plan` on ISSUE-6, 4 compactions
in 16 minutes) showed `sdd:plan` reads exactly what its SKILL.md promises: the
single input file plus at most one predecessor log. The actual context growth
came from `superpowers:writing-plans`'s own codebase exploration (source files,
DESIGN.md, SPEC.md grep, README.md) plus multi-turn checkpoint dialogue in one
long uncleared session — expected behavior, not a defect. Same pattern
reconfirmed for `sdd:implement` and `sdd:verify` sessions.

## Finding 1 — Missing `/clear` between `sdd:verify` (PASS) and `sdd:finalize`

`sdd:finalize` has no dependency on conversation history: Step 1 is
`git status --short`, Step 2 delegates to `commit-message` (reads the diff from
disk), Step 3 asks the user directly whether to re-run tests. Unlike
`sdd:revise`, nothing here requires memory of the just-completed verify run.

**Fix:** add a "Before Starting" section to `sdd:finalize/SKILL.md` requesting
`/clear`, matching the pattern already used in `plan` and `verify`.

## Finding 2 — Subagent dispatch pastes full plan content into the prompt

`sdd:implement` Step 2 (implementation subagent) and Step 4 (testing subagent),
plus `sdd:revise` Step 2c (fix subagent), instruct: *"Replace `<PLAN_CONTENT>`
with the full content of the plan file read in Step 1."* This text becomes part
of the orchestrating skill's own tool-call payload — i.e. it inflates the
*parent* skill's context, not just the subagent's isolated context. It also
risks the subagent receiving a corrupted/paraphrased copy if the parent thread
was already compacted before dispatch.

**Fix:** change the dispatch instruction in all three call sites to tell the
subagent the plan file's path and instruct it to read the file itself, instead
of embedding the plan content in the prompt.

## Finding 3 — Granularity checkpoint in `sdd:plan` Step 4 fires on every run

Unlike Checkpoint 1 (slug) and Checkpoint 2 (branch strategy), which are marked
`⛔ CHECKPOINT ... MANDATORY, do not skip`, the granularity choice has no such
marker. The skill's own text already recommends "Balanced" as the default
unless the input suggests otherwise.

**Fix:** auto-select "Balanced" without prompting, except when the ISSUE-N.md
content clearly signals unusually large/complex or unusually trivial scope —
only then ask the three-option question.

Note: a related upfront-granularity-choice feature already shipped under
`docs/sdd-skill-improvements-DESIGN.md` (Item 3) — this finding is about
*removing* the prompt in the common case, not adding the choice; it does not
conflict with that prior work, which is about presenting the choice upfront
rather than retroactively.

## Finding 4 — Recurring `sdd:implement` failure: "File has not been read yet"

Confirmed in transcript (session `9e2d66c8`, `/sdd:implement` on PLAN-7):
```
agent-aa39da965b6decddc.jsonl:17  <tool_use_error>File has not been read yet. Read it first before writing to it.</tool_use_error>
agent-a3db20fc9d58c96d9.jsonl:23  <tool_use_error>File has not been read yet. Read it first before writing to it.</tool_use_error>
```
Root cause: `sdd:implement` Step 2 delegates to
`superpowers:subagent-driven-development`, which spawns a fresh, isolated
subagent per task (`spawnDepth: 2`). When a later task needs to modify a file a
prior task already created, the new subagent never read that file in its own
context, tripping the Write/Edit read-before-write guard.

Observed workaround (functional but risky): instructing the subagent to fall
back to a raw shell command (sed/cat) when Edit fails. This bypasses Edit's
exact-match anti-corruption protection and can silently produce wrong edits.

**Fix:** add an explicit rule to the task-dispatch prompt (in `sdd:implement`'s
Step 2, and anywhere `subagent-driven-development` is invoked from this
plugin): *"Before every Write or Edit on a file — even one you believe a prior
task already created — Read it first in this subagent's own context. Never
fall back to a raw shell command to bypass an Edit/Write failure; Read the file
and retry the tool instead."*

## Finding 5 — `sdd:verify` Step 3 always fails to invoke `codex:review`

Root cause confirmed by reading
`~/.claude/plugins/cache/openai-codex/codex/1.0.5/commands/review.md`:
`codex:review` is a slash **command**, not a skill, with
`disable-model-invocation: true` in its frontmatter — it can only be typed
literally by the user, never called by the model via the `Skill` tool.
`sdd:verify` Step 3 currently says "Run `/codex:review --wait`," which the
model interprets as a `Skill` tool call and which always errors.

Observed workaround in a real session: the model discovered and used
`codex review --uncommitted "..."` directly via Bash, calling the `codex`
binary instead of going through the slash command.

**Fix:** rewrite `sdd:verify` Step 3 to invoke `codex review --uncommitted ...`
(or the equivalent flag for base-branch review) directly through Bash, not
through the `Skill` tool.

## Finding 6 — Ambiguous merge/cleanup wording in `sdd:verify` Step 7 (cosmetic)

Verified against 2 real PASS sessions (`3b2e1f68`, `bb88af8e`): `sdd:verify`
never merges or opens a PR itself — every PASS case correctly routes through
`sdd:finalize` → `superpowers:finishing-a-development-branch`. No functional
defect found. However, Step 7's question — *"The implementation is validated.
Would you like to merge and clean up?"* — reads as if `verify` itself performs
the merge, even though the "Yes" branch immediately hands off to `sdd:finalize`.

**Fix:** reword the question to name `sdd:finalize` explicitly, e.g. *"Would
you like `sdd:finalize` to merge and clean up?"*, removing the ambiguity.

## Suggested handoff

Feed this file to `/sdd:design docs/sdd-context-hygiene-DESIGN.md` (or a
different slug, if preferred) to confirm scope/outcome/success criteria before
`/sdd:plan` turns it into an implementation plan. Findings 1-6 all fall inside
`plugins/spec-driven-development/skills/{plan,implement,verify,revise,finalize}/SKILL.md`
— no code changes, no changes to `superpowers:*` skills themselves, only to how
these five skills invoke them or dispatch subagents.
