---
name: fix
description: Bug fix playbook — trace, fix, verify, document
---

# Bug Fix Playbook

## 1. Trace
- Read the error output / bug report. Work from raw data, not theories.
- Reproduce the issue. If you can't reproduce, ask for steps / logs.
- Identify the root cause file(s). Grep for relevant symbols.

## 2. Scope
- Name the exact file(s) you will edit. No others.
- State the fix in one sentence before touching code.

## 3. Fix
- Fix the root cause, not the symptom.
- If the fix touches >3 files, pause and confirm scope with the user.

## 4. Verify
- Run type-checker
- Run linter
- Run tests (especially tests related to the bug)
- If no test covers this bug, write one that would have caught it.

## 5. Document
- If the bug was caused by a non-obvious pattern, add a rule to `gotchas.md`.

$ARGUMENTS
