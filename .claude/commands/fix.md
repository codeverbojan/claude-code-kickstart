---
name: fix
description: Bug fix playbook — trace, fix, verify, document
---

# Bug Fix Playbook

Fix the root cause, not the symptom. Trace first, always — otherwise you'll
fix the wrong thing and the real bug will come back.

This playbook runs under CLAUDE.md §4 Execution Loop: one fix, tests in the
same turn, parallel review before closing.

## 1. Trace
- Read the raw error output / bug report. Work from data, not theories.
- Reproduce the issue. If you can't, ask for steps or logs before guessing.
- Identify the root-cause file(s). Grep for relevant symbols; for non-trivial
  traces, prefer SocratiCode (`codebase_search`, `codebase_graph_query`).
- State the root cause in one sentence. Write it down — review agents will
  check against it.

## 2. Scope
- Name the exact file(s) you will edit. No others.
- State the fix in one sentence before touching code.
- If the fix touches >3 files, pause and confirm scope with the user.

## 3. Fix + test
- Fix the root cause.
- Write a regression test in the same turn — one that would have caught this
  bug. If the project has no test infra, state so explicitly.
- Update related tests if behavior legitimately changed.

## 4. Checkpoint review (parallel)
Spawn in a single message:
- `code-reviewer` — did the fix address the stated root cause?
- `test-runner` — full suite passes, regression test actually covers the bug.
- `security-reviewer` — if the bug touched auth, inputs, DB, or APIs.
- `accessibility-reviewer` — if the bug is in a UI component.

Give every reviewer the root-cause sentence from step 1 + the files touched.
Fix all valid findings before reporting done.

## 5. Report (use the §4 format)
```
Task: <one-line bug description>
Implementation: <root cause + fix in 1-2 lines>
Tests: <regression test added, suite pass/fail>
Review findings: <bullets, or "clean">
Fixes: <response to findings, or "none">
Status: <complete | blocked: reason>
```

## 6. Document
If the bug came from a non-obvious pattern, append a rule to `gotchas.md`.

$ARGUMENTS
