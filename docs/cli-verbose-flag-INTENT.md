# Intent: CLI Verbose Flag
Confirmed: 2026-06-30

## Outcome
Add a --verbose boolean flag to the CLI script that prints step-by-step progress logging.

## User
Developers/operators running the script who need diagnostic visibility into what it's doing.

## Why Now
Throwaway dry-run example (no real "why now" — this is a test feature).

## Success Criteria
Running with --verbose shows step-by-step progress; without it, output stays unchanged.

## Constraints
No raw request/response payloads in verbose output (avoid leaking sensitive data).

## Out of Scope
Leveled verbosity (-v/-vv), structured/JSON log output.
