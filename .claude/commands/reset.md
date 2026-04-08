---
name: reset
description: End current work, save state, clear context, and start fresh with full onboard
---

# Reset Session

Three phases, in order. Don't skip.

## Phase 1: Wrap up
Run the full `/wrap-up` flow: verify, rewrite `primer.md`, update
`decisions.md`/`gotchas.md`/`metrics.jsonl`. Don't report to the user yet.

## Phase 2: Clear context
Tell the user: "Session state saved. Clearing context and restarting fresh."
Then run `/clear`.

## Phase 3: Deep onboard
The SessionStart hook auto-loads `primer.md` (and any non-stub
gotchas/patterns/decisions) on session resume. Then run `/onboard deep` to
get the full project explore + status report.

If the user provided a task with `/reset`, pass it through to `/onboard deep`
so the onboard focuses on that task.

## When to use
- Context is degraded (forgetting files, editing stale content, hallucinating).
- Switching to a completely different area of the codebase.
- After a long session (20+ messages).
- After a large merge or rebase.

$ARGUMENTS
