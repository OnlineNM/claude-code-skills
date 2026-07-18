# Spec Review Log: SDD Context Hygiene
Act 1 (brainstorming) complete — spec locked with user. MAX_ROUNDS=5.

## Round 1 — Codex
**Findings**

1. **Contradictory implementation mechanism.** The spec says “use `skill-creator` rather than raw ad-hoc Edit/Write calls,” but the actual requested changes are plain edits to existing `SKILL.md` files; `skill-creator` may be overkill or may not define a concrete edit workflow.
Fix: Specify exactly which `skill-creator` instructions/validation steps must be used, or remove the mandate and require normal scoped text edits plus validation.

2. **Finding 2 is under-specified.** “Replace `<PLAN_CONTENT>` with the plan file’s path” does not state whether the XML tag remains `<plan>`, becomes `<plan_path>`, or whether downstream prompts expect the old tag.
Fix: Define the exact replacement text for both template blocks.

3. **Path-passing may fail across subagent contexts.** The spec assumes subagents can read the same relative path, but does not require absolute paths or define cwd assumptions.
Fix: Require passing the absolute plan file path, or explicitly state the path must be relative to the repository root and tell the subagent its cwd.

4. **Finding 2 may still leak context if the surrounding prompt includes plan summaries elsewhere.** The spec only targets two `<PLAN_CONTENT>` placeholders and assumes this fully fixes content pasting.
Fix: Add a requirement to verify no remaining dispatch prompt includes full plan content.

5. **Finding 3 has vague trigger criteria.** “Clearly signals unusually large/complex or unusually trivial scope” is subjective enough that future runs may still ask every time or never ask.
Fix: Add qualitative examples of signals that should trigger the question, while still avoiding numeric thresholds.

6. **Finding 3 omits the exact new default behavior.** It says auto-select Balanced, but not whether the skill should tell the user, silently proceed, or record the choice.
Fix: Specify the exact wording or behavior when Balanced is auto-selected.

7. **Finding 4’s read-before-write rule may be impossible for brand-new files.** “Before every Write or Edit on a file ... Read it first” conflicts with creating a file that does not yet exist.
Fix: Clarify: Read existing files before Edit/Write; for new files, first confirm absence with an allowed read/list operation, then Write.

8. **Finding 4 over-constrains tool behavior.** “Never fall back to a raw shell command” is good for bypassing guards, but could accidentally forbid legitimate shell operations like tests, formatting, or mkdir.
Fix: Narrow the prohibition to using shell commands to create/modify files after an Edit/Write read-before-write failure.

9. **Finding 5 lacks the actual Codex review prompt.** `codex review --uncommitted "..."` has an ellipsis where a real review instruction should be.
Fix: Provide the exact command string, including the review prompt text and quoting requirements.

10. **Finding 5 assumes `codex` is installed and authenticated.** The spec replaces an impossible slash command with a CLI dependency but does not define fallback behavior if the binary is unavailable.
Fix: Add a failure path: if `codex` is unavailable, report that Codex review could not run and continue/fail according to a specified rule.

11. **Finding 5 may hang or require network/model access.** `codex review` could be slow, interactive, or unavailable in restricted environments.
Fix: Require a non-interactive invocation, timeout expectation, and explicit handling for nonzero exit codes.

12. **Finding 6 is called cosmetic but changes user-facing control flow wording.** The branch behavior depends on whether `sdd:finalize` is actually invoked automatically or only suggested.
Fix: State the exact Yes/No branch behavior after the revised question.

13. **Line-number dependency is brittle.** The spec anchors several edits to historical line numbers while also saying implementation happens later.
Fix: Anchor edits by headings and nearby unique text, with line numbers as advisory only.

14. **Verification is too weak.** “Re-reading resulting SKILL.md text” catches textual presence but not contradictions, duplicated instructions, or broken prompt structure.
Fix: Require verifying each modified section still reads coherently in full and that no duplicate/conflicting instruction remains nearby.

15. **Scope excludes tests but not formatting/metadata churn.** The spec says text-only docs, but does not explicitly forbid unrelated formatting changes in the five files.
Fix: Add “no unrelated reflow, formatting churn, or edits outside the specified sections.”

16. **No rollback criteria.** If one finding conflicts with existing skill structure during implementation, the spec says “None outstanding” and gives no escalation path.
Fix: Require stopping and reporting if the existing files differ materially from the assumed structure.

VERDICT: REVISE### Claude's response
Accepted and applied: #1 (clarified skill-creator scope: its modify-existing-skill workflow + structural validation), #2 (exact `<plan_path>` replacement text defined), #3 (absolute path required), #4 (verification step added to grep for leftover plan content), #5 (concrete example signals added for Finding 3's trigger, still qualitative per user decision), #6 (Balanced auto-select proceeds silently, stated explicitly), #7 (read-before-write rule now exempts genuinely-new files), #8 (shell-command prohibition narrowed to "forcing through after an Edit/Write failure", not banning all shell use), #9 (concrete Codex review prompt text substituted for the ellipsis), #10 (fallback behavior added: report and let user decide if codex is unavailable/fails), #11 (non-interactive invocation stated explicitly), #13 (Approach section now frames line numbers as advisory, anchored by heading/text; added a stop-and-report rule for structural drift), #14 (new Verification section added: coherence re-read, no duplicate/contradictory instructions), #15 (explicit "no unrelated reflow/formatting" rule added to Approach), #16 (stop-and-report rule added to Approach, covering escalation on structural mismatch).

Rejected: #12 (Finding 6 branch-behavior ambiguity) — the Yes/No sub-options and control flow are unchanged by this edit; only the question's own wording changes. Added one clarifying sentence to close off any doubt, but the underlying concern (that behavior itself is ambiguous) doesn't apply since Finding 6 never touches the sub-option text.

## Round 2 — Codex
**Prior Findings**

Most prior issues are addressed: line-number brittleness, exact Step 7 wording, Codex CLI fallback, qualitative examples for granularity, read-before-write nuance for new files, verification scope, and no unrelated reflow are all improved.

**Remaining / New Flaws**

1. **Finding 1 conflicts with Finding 6’s unchanged handoff.** `verify` Step 7 still says Yes invokes `sdd:finalize`, but `finalize` will now immediately tell the user to `/clear` and re-invoke, so the “Yes” branch no longer actually proceeds to merge/cleanup in that same flow.
Fix: Update `verify` Step 7 behavior/wording to say Yes hands off to `sdd:finalize`, which may first require `/clear`, or define a bypass when invoked from a verified clean context.

2. **Finding 2 still does not give the exact replacement block.** It says replace `<plan>...</plan>` with `<plan_path>...</plan_path>` containing the absolute path, but implementation-time docs should contain a placeholder, not a real path.
Fix: Specify the exact template block as `<plan_path><PLAN_PATH></plan_path>`.

3. **Finding 2 verification phrase is too broad.** “No other line in either template still references or restates plan content” could accidentally prohibit legitimate references like “read the plan file.”
Fix: Change this to “no line embeds or instructs pasting the full plan content.”

4. **Finding 4 has a tool-name mismatch risk.** The bullet says “Edit or Write fails,” but some environments distinguish `Edit`, `Write`, `MultiEdit`, `apply_patch`, or shell edits; the intended rule is about file mutation, not only two tool names.
Fix: Either name the exact tools used by those skills, or phrase it as “file-modification tool failure” and include the known tool names parenthetically.

5. **Finding 5 does not define timeout mechanics.** It says auth failure/timeout should be handled, but the command itself has no timeout wrapper or maximum wait.
Fix: Specify the actual timeout behavior, e.g. “run with Bash timeout of N seconds/minutes if available; otherwise stop and ask before waiting longer.”

6. **Finding 5 may produce review output but no pass/fail integration.** The spec says Codex should report issues, but does not say how Step 4 should treat findings from Codex.
Fix: Add whether any concrete Codex finding blocks PASS, gets merged into the verification report, or is advisory only.

7. **The `skill-creator` requirement remains operationally vague.** “Modify-existing-skill workflow” and “structural-validation steps” are not named commands or files; implementers may still interpret this differently.
Fix: Reference the exact `skill-creator` section names or required checklist items to follow.

8. **Verification item 4 is internally inconsistent.** It says grep `revise/SKILL.md` to confirm no remaining prompt text embeds full plan content, but the spec intentionally makes no edit there and says it delegates by reference.
Fix: Clarify that `revise/SKILL.md` should be checked only for direct full-plan embedding, not for references to `implement`’s pattern.

VERDICT: REVISE### Claude's response
Accepted and applied: #1 (added explicit same-session handoff exception from `verify` Step 7, so the new /clear prompt doesn't block the existing Yes-branch handoff), #2 (exact `<plan_path><PLAN_PATH></plan_path>` placeholder-token template defined), #3 (narrowed verification wording to "embeds or instructs pasting" only), #4 (named the exact tools — Read/Edit/Write — matching this harness, removed ambiguity about other tool names), #5 (added explicit Bash timeout guidance and defined Codex findings as advisory input into verify's overall verdict, not auto-blocking), #8 (clarified verification item 4: revise/SKILL.md is checked only for its own literal content embedding, its reference-by-name to implement's pattern is expected/unchanged).

Partially accepted: #7 (skill-creator vagueness) — rather than inventing skill-creator's exact internal step/command names (which I haven't verified and which risks going stale independently of this spec), the spec now explicitly delegates to skill-creator's own SKILL.md at implementation time as the source of truth for its exact edit-existing-skill workflow. Pre-enumerating skill-creator's internals here would duplicate content this spec doesn't own.

## Round 3 — Codex
Prior findings are materially addressed. The revised spec now gives implementable anchors, exact placeholder behavior, verification checks, Codex failure handling, Step 7 handoff behavior, and a clearer `skill-creator` delegation model.

Remaining nits, not blockers:

1. **“One targeted text edit” is still imprecise.** Findings 2 and 4 each require edits in two template blocks.
Fix: Say “one targeted change per finding, applied to each named occurrence.”

2. **Finding 1’s handoff exception weakens the original context-hygiene rule.** Skipping `/clear` when `finalize` is invoked from `verify` preserves convenience but means `finalize` can still run in a large verification context.
Fix: Keep as-is if intentional, but acknowledge this as an accepted tradeoff in “Key decisions.”

3. **Absolute paths may leak local filesystem details into subagent prompts/logs.** This is probably acceptable for local workflow correctness, but it is still a privacy tradeoff.
Fix: Add a short tradeoff note that absolute paths are intentionally used despite exposing local path strings inside session transcripts.

4. **Codex timeout remains example-based.** “A few minutes” is enough for a human implementer, but not fully deterministic.
Fix: Optionally specify a concrete timeout, e.g. 300 seconds.

None of these are material enough to block implementation planning.

VERDICT: APPROVED