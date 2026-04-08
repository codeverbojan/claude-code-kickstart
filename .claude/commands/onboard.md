---
name: onboard
description: Session onboarding — light by default, add "deep" for full context load
---

# Session Onboard

`primer.md` is auto-loaded by the SessionStart hook, so skip anything that
just re-reads it. Mode is determined by `$ARGUMENTS`.

## DEEP MODE — if `$ARGUMENTS` contains "deep"

Full context load for major work. Read in this order, skipping any file that
contains a placeholder stub (`No gotchas yet`, `No patterns extracted yet`,
`No decisions logged yet`) — those have no signal:

1. `gotchas.md`, `patterns.md`, `decisions.md` (non-stub only)
2. Project structure: key directories, entry points, top-level config
3. Architecture docs if present (`docs/`, `ARCHITECTURE.md`, `README.md`)
4. `git status` for uncommitted state
5. Typecheck/lint if configured — otherwise skip silently

Report in under 15 lines:
- Current state (from primer.md)
- Project structure (one line)
- Uncommitted changes
- Test/lint health or "not configured"
- Next steps from primer.md
- Blockers or clarifications needed

If a task was given alongside "deep", also name the 1–3 files you'll need
and how the task fits the current state.

## LIGHT MODE — if a task is given (no "deep")

Fast onboard for focused work.

1. Identify the 1–3 files most relevant to `$ARGUMENTS`
2. Report in 3–5 lines: current state, what you'll work on, files you'll
   touch, any blocker
3. Start working immediately.

## STATUS MODE — no arguments

Just report `git status` + next steps from primer.md in 3 lines. Don't
re-read primer.md — it's already in context. Wait for instructions.

$ARGUMENTS
