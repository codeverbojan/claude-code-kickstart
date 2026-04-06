---
name: onboard
description: Session onboarding — light by default, add "deep" for full context load
---

# Session Onboard

Determine the mode based on `$ARGUMENTS`:

## If "deep" is in the arguments → DEEP MODE

Full context load for major work:

1. Read `primer.md` — current state, next steps, blockers
2. Read `gotchas.md` — all rules learned from past mistakes
3. Read `patterns.md` — how this project does things (if populated)
4. Read `decisions.md` — why past decisions were made (don't re-litigate these)
5. Explore project structure — key directories, config files, entry points
6. Check `git status` for uncommitted changes
7. Run type-checker/linter if configured, report health
8. Read any architecture docs if they exist (docs/, ARCHITECTURE.md, etc.)
9. Report back:
   - Where are we? (current state, what's done, what's not)
   - Project structure overview
   - Uncommitted changes or dirty state
   - Test/lint health
   - Exact next steps from primer.md
   - Any blockers or risks
   - What should be clarified before starting?

If a task was given alongside "deep", also report how the task fits into
the current project state and which files you'll need.

## If a specific task is given (no "deep") → LIGHT MODE

Fast onboard for focused work:

1. Read `primer.md` — current state, next steps
2. Read `gotchas.md` — rules to follow
3. Identify the 1-3 files most relevant to the task
4. Report in 3-5 lines:
   - Current state (one line)
   - What you'll work on
   - Which files you'll touch
   - Any blockers
5. Start working immediately.

## If no arguments → STATUS MODE

Quick status check:

1. Read `primer.md`
2. Read `gotchas.md`
3. Check `git status`
4. Report:
   - Current state from primer.md
   - Any uncommitted changes
   - Next steps from primer.md
5. Wait for instructions. Do not start working.

$ARGUMENTS
