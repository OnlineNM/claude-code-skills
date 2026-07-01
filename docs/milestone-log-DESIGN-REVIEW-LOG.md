# Spec Review Log: Issue Implementation Log
Act 1 (brainstorming) complete — spec locked with user. MAX_ROUNDS=5.

## Round 1 — Codex
**Material Flaws**

1. The spec assumes issue number parsing is trivial, but filenames may include multi-digit issue numbers, extra suffixes, or nonstandard casing.
Fix: Define the exact filename regex for issue, plan, and log discovery, e.g. `^docs/(.+)-ISSUE-([0-9]+)\.md$`.

2. Slug extraction is ambiguous when the slug itself contains `-ISSUE-`.
Fix: Parse from the rightmost `-ISSUE-<N>.md` suffix, or explicitly forbid `-ISSUE-` in slugs.

3. “Same PRD” is inferred only from slug, which may be insufficient if docs contain copied/renamed issues or duplicate slug families.
Fix: Require `sdd:plan` to derive the PRD path from the issue’s existing convention and confirm the predecessor log belongs to that slug/PRD.

4. Reading only `N-1` creates fragile transitive context, but the log format does not require `N-1` to restate durable facts from earlier issues.
Fix: Add a required “Continuing assumptions / durable context for later issues” subsection to the log.

5. The writer lifecycle says `sdd:implement` writes the log after “Implementation complete,” but does not say whether failed, partial, or user-interrupted implementations get a log.
Fix: Specify logs are written only after completed implementation, and partial work should either not create a log or clearly mark status as incomplete.

6. The log can become stale if code changes after `sdd:implement` but before `sdd:verify`.
Fix: Require `sdd:verify` to compare the log against the final working tree and update inaccurate implementation claims.

7. The verify behavior is underspecified: “updates the Verification section” could append duplicate sections, overwrite useful text, or corrupt markdown.
Fix: Define deterministic replacement of exactly the `## Verification` section, preserving other sections.

8. There is no behavior for a missing log during `sdd:verify`.
Fix: Specify whether `sdd:verify` creates the log, fails with guidance, or no-ops; preferably create it with implementation sections marked unavailable.

9. There is no behavior when `sdd:implement` is rerun for the same issue and a log already exists.
Fix: Require overwrite, merge, or prompt behavior; preferably replace generated sections after rereading the current diff and preserve verification only if still valid.

10. “What was built” asks for files modified, schema changes, routes, and decisions, but does not define how exhaustive this must be.
Fix: Require enough specificity for future planning: changed files grouped by purpose, public contracts, schema/API changes, and known follow-on constraints.

11. The artifact may leak sensitive implementation details into `docs/`, especially if logs summarize env vars, credentials, private endpoints, customer data, or security decisions.
Fix: Add a redaction rule: logs must not include secrets, tokens, credentials, private data, or exploit-enabling security detail.

12. The “What's new in the app” section assumes every issue has user-facing app changes.
Fix: Allow “No user-facing change” for infra, test, refactor, or internal-only issues.

13. The spec says “non-technical reviewer,” but logs are consumed by `sdd:plan`; those audiences conflict.
Fix: Separate audience requirements: user-facing summary first, technical planning context second.

14. `sdd:plan` discovery says “Step 1,” but does not define how the discovered log is prioritized against PRD text and code reading.
Fix: State the log is supplemental and must not override the current issue spec, PRD, or observed code.

15. There is no warning when a predecessor log exists but is unverified.
Fix: Require `sdd:plan` to treat “Not yet verified” logs as lower-confidence context and mention that in the generated plan.

16. There is no handling for predecessor log contradictions against the codebase.
Fix: Require `sdd:plan` to prefer actual code over the log and call out contradictions.

17. The log filename collides conceptually with issue documents and plans, increasing docs clutter in the flat convention.
Fix: Consider `docs/<slug>-LOG-N.md` or a dedicated generated-log naming pattern, or explicitly accept and document the clutter.

18. The spec does not state whether logs are committed artifacts or temporary local agent memory.
Fix: Declare logs are source-controlled project artifacts unless the repo’s normal docs policy says otherwise.

19. The approach adds write responsibilities to three skills but does not address consistency across their prompts/instructions.
Fix: Define a shared mini-template or helper wording so implement, verify, and plan use the same section names exactly.

20. “No new flags/options” removes user control even when the log is known wrong or noisy.
Fix: Add no flag if simplicity matters, but allow an inline manual override in the issue file or skill invocation text such as “ignore prior issue log.”

21. The plan step says read only the prior log “to avoid unnecessary context load,” but logs could become arbitrarily long.
Fix: Add a size guideline or require concise logs with a maximum target length.

22. Verification updates could erase evidence of discrepancies that were fixed during verify.
Fix: Require verification text to distinguish “confirmed,” “fixed during verification,” and “remaining discrepancy.”

23. The format does not include implementation status, date, tool/skill source, or issue identifier beyond title.
Fix: Add a short metadata line or require the H1 to include exact issue number and slug.

24. The spec assumes issue N always depends most on issue N-1, which is often false for parallel feature slices.
Fix: Allow the current issue file to explicitly reference additional prior logs when needed, while keeping automatic discovery to N-1.

25. There is no migration story for existing completed issues without logs.
Fix: State old issues remain unsupported unless manually backfilled, and `sdd:plan` no-ops when the predecessor log is absent.

26. The implementation touchpoints omit tests or validation for these skill changes.
Fix: Add acceptance tests or manual test cases covering issue 1, issue 2 with log, missing log, multi-digit issue numbers, rerun implement, and verify update.

27. “Inspired by milestone-log pattern” references `docs/milestone-log-INTENT.md`, but the spec does not say whether implementation must read or conform to it.
Fix: Either make that document normative and list required borrowed behavior, or remove the reference as non-binding background.

28. The log may create false confidence because it is generated by the same agent that implemented the issue.
Fix: Require `sdd:verify` to independently validate the log’s claims against plan/code before marking verification complete.

29. The verify section says “after it confirms plan compliance,” but also says it records discrepancies found/fixed; those states are mutually fuzzy.
Fix: Define verification outcomes: `Verified`, `Verified after fixes`, `Not verified`, or `Discrepancies remain`.

30. The spec does not say what happens if `docs/` does not exist.
Fix: Require the skills to create `docs/` only if the existing repo convention already expects it, otherwise fail with a clear message.

VERDICT: REVISE
### Claude's response
Accepted (folded into DESIGN.md):
- #1/#2 filename ambiguity → reuse sdd:plan's existing slug/N extraction, log = same slug + N (or N-1 for predecessor)
- #7/#29 verification section semantics → deterministic replace of only `## Verification`, fixed enum: Not yet verified / Verified / Verified after fixes / Discrepancies remain
- #9 rerun behavior → sdd:implement overwrites the whole log on rerun, resets Verification
- #8 missing log at verify time → sdd:verify no-ops on the log if absent
- #12 non-UI issues → allow "No user-facing change"
- #14/#16 log vs code/PRD authority → log is supplemental only, code/PRD win on conflict, discrepancies noted
- #15 unverified log confidence → sdd:plan flags "Not yet verified" predecessor logs as lower-confidence

Rejected (over-engineering for a lightweight internal skill spec, not production software):
- #11 redaction/secrets policy — no different from any other docs/ file in this repo, not specific to this feature
- #26 formal acceptance tests — this is an agent-skill instruction change, not a codebase with a test suite
- #28 independent re-validation of log claims — that's exactly sdd:verify's existing job, no new mechanism needed
- #3 same-PRD confirmation beyond slug — slug is already the sole identity key throughout sdd:prd/plan/implement
- #20 manual override flag — user explicitly chose always-on/no-flag; can revisit later if it proves wrong in practice
- #21 log length guideline, #17 alternate filename, #19 shared template file, #24 N-2 dependency handling, #25 migration story, #30 docs/ existence handling — all already implicitly covered or genuinely out of scope per "Out of scope" section

## Round 2 — Codex
The revision addresses several prior concrete issues: filename parsing is now defined, rerun behavior is specified, missing verify-log behavior is explicit, unverified predecessor logs are lower-confidence, log/code contradictions are handled, and no-user-facing-change issues are covered.

Remaining material flaws:

1. The stated goal includes giving `sdd:implement` visibility into the prior issue, but Discovery only updates `sdd:plan`.
Fix: Either add the same predecessor-log read to `sdd:implement`, or narrow the goal to `sdd:plan` only.

2. `sdd:verify` now writes only one of four status strings, which removes the earlier requirement to record what was confirmed or what discrepancies were found/fixed.
Fix: Keep the status as the first line, then allow concise bullets underneath for confirmed scope, fixes made, or remaining discrepancies.

3. The Implementation touchpoints still say `verify/SKILL.md` should “append/update” the Verification section, while lifecycle says “replaces only.”
Fix: Change the touchpoint to “replace only the `## Verification` section content.”

4. “Discrepancies remain” without details is not actionable for future `sdd:plan`.
Fix: Require `Discrepancies remain` to include at least one bullet naming the discrepancy and affected file/behavior.

5. The spec still does not require redaction of secrets or sensitive implementation details.
Fix: Add a rule that logs must not include credentials, tokens, private data, secret env values, or exploit-enabling security details.

6. The “What was built” section is still under-specified for future planning, especially given the N-1-only context tradeoff.
Fix: Require durable context to be included when relevant: public contracts, schema/API changes, important helpers, migrations, and decisions future issues may depend on.

7. There is no size or concision guard, so always-on context can grow without bound.
Fix: Add a target length, e.g. “keep logs concise, preferably under ~100 lines unless the issue genuinely requires more.”

8. Missing log on `sdd:verify` no-ops silently, which can hide a broken `sdd:implement` lifecycle.
Fix: Require `sdd:verify` to note that the expected log was missing in its normal verification output, even if it does not create the file.

9. The spec says `sdd:plan` should note code/log discrepancies, but does not say where.
Fix: Require the generated plan to include a short “Prior log discrepancy” note when this happens.

10. There are still no acceptance checks for the skill behavior.
Fix: Add manual test cases for issue 1 no-op, issue 2 reads verified log, issue 2 reads unverified log, missing predecessor log, rerun implement overwrite, and verify section replacement.

VERDICT: REVISE
### Claude's response
Accepted: #1 (goal narrowed to sdd:plan only, matches Discovery section which was always plan-only), #2 (Verification allows detail bullets under the status line), #3 (touchpoints wording fixed to match "replace only"), #4 (Discrepancies remain requires a naming bullet), #7 (soft ~100-line concision guidance added), #8 (sdd:verify notes missing log in its own output), #9 (sdd:plan adds "Prior log discrepancy" note in generated plan), #6 (folded lightly: public contracts/migrations added to What was built guidance).
Rejected (same reasoning as round 1, still out of scope for a lightweight internal skill spec): #5 redaction/secrets policy, #10 formal acceptance tests.

## Round 3 — Codex
Most prior findings are now addressed. The goal is narrowed to `sdd:plan`, verification details are restored, missing-log behavior is explicit, discrepancy notes have a destination, concision is specified, and the touchpoint conflict is fixed.

Remaining issues:

1. The spec still lacks a redaction/security rule for generated logs.
Fix: Add: “Logs must not include secrets, tokens, credentials, private data, raw env values, customer data, or exploit-enabling security details.”

2. `sdd:implement` is told to write “What was built,” but not explicitly told to base that section on the actual completed changes rather than the intended plan.
Fix: Require `sdd:implement` to summarize the actual final implementation/worktree state, not just the planned work.

3. There are no acceptance checks for the skill changes.
Fix: Add manual test cases for issue 1 no-op, issue 2 with verified predecessor log, unverified predecessor log, missing predecessor log, implement rerun overwrite, and verify section replacement.

4. “Reuse the same slug/issue-number extraction `sdd:plan` already does” is only safe if that current extraction already uses the rightmost suffix behavior.
Fix: If the current code/instructions do not already do that, the implementation must update extraction consistently for issue-to-plan and issue-to-log paths.

These are relatively small, but the redaction rule is still a material omission for generated documentation that may be committed.

VERDICT: REVISE
### Claude's response
Accepted: #2 (implement writes log from actual final state, not just plan intent), #4 (implementation touchpoint note to verify/fix rightmost-suffix extraction consistency).
Rejected again, same reasoning as rounds 1-2 (final arbiter call, not revisiting further): #1 redaction/secrets policy — this repo's docs/ files carry no different risk profile than any other spec/plan doc already produced by sdd:prd/sdd:plan; adding a bespoke rule here is scope creep. #3 formal acceptance tests — no test suite exists for agent-skill instruction files in this plugin; sdd:verify already exercises the real behavior end-to-end when the feature is implemented.

## Round 4 — Codex
Prior findings are mostly addressed within the scope you set. The goal now matches `sdd:plan`, implementation logs are based on actual worktree state, filename parsing has an implementation check, verification details are useful again, and the missing-log behavior is explicit.

One remaining edge case, but I would not block on it:

1. If `sdd:verify` makes fixes after implementation, `## What was built` may become stale because verify is required to leave it untouched.
Fix: Either allow `sdd:verify` to update `What was built` when its fixes materially change the implementation summary, or require the `Verified after fixes` bullets to describe those final changes clearly enough for `sdd:plan`.

That is not enough to hold the spec. The behavior is coherent, scoped, and implementable.

VERDICT: APPROVED
### Claude's response
VERDICT: APPROVED. Folded the one remaining non-blocking edge case: "Verified after fixes" bullets must now describe fixes clearly enough that the untouched `What was built` section isn't misleading on its own. Spec finalized after 4 rounds.
