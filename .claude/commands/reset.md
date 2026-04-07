---
name: reset
description: End current work, save state, clear context, and start fresh with full onboard
---

# Reset Session

Properly end the current work and start fresh. This runs three phases
in sequence — do NOT skip any phase.

## Phase 1: Wrap Up (save everything)

Execute the full /wrap-up flow:

1. Run type-checker/linter if any code changed
2. Rewrite `primer.md` with structured handoff format
3. Update `decisions.md` if decisions were made (check for duplicates)
4. Update `gotchas.md` if mistakes were made
5. Append session metrics to `.claude/metrics.jsonl`

Do NOT report to the user yet — continue to Phase 2.

## Phase 2: Clear Context

Tell the user:
"Session state saved. Clearing context and restarting fresh."

Then run `/clear` to reset the context window.

## Phase 3: Deep Onboard

After the context is cleared, the SessionStart hook will auto-load
primer.md, gotchas.md, patterns.md, decisions.md, and git history.

Then execute the full deep onboard:

1. Read `primer.md` — current state from the session you just saved
2. Read `gotchas.md` — all rules including any just added
3. Read `patterns.md` — code patterns (if populated)
4. Read `decisions.md` — settled decisions (don't re-litigate)
5. Explore project structure
6. Check `git status`
7. Run type-checker/linter if configured
8. Report full status

If the user provided a task with this command, focus the onboard on that task.

## When to Use This

- Context is degraded (forgetting things, editing stale content)
- Switching to a completely different area of the codebase
- After a long session (20+ messages) — fresh context = better quality
- After a large merge or rebase (project state has changed significantly)

$ARGUMENTS
