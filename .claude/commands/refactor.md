---
name: refactor
description: Refactor playbook — clean up without changing behavior
---

# Refactor Playbook

## 1. Scope
- State what you're refactoring and why (not just "cleanup").
- Name the exact files. Refactors that touch >5 files need phases.

## 2. Delete First
- Before restructuring: remove dead props, unused exports, unused imports,
  debug logs. Commit cleanup separately.

## 3. Refactor
- Change structure, not behavior. Tests must still pass.
- When renaming, search thoroughly: calls, types, strings, imports,
  re-exports, tests, mocks. Assume a single grep missed something.

## 4. Verify
- Run type-checker
- Run linter
- Run full test suite (refactors can break things you don't expect)
- Verify no behavior change — same inputs, same outputs.
- Show passing output. "It's just a rename, it'll be fine" is rationalization.

## 5. Review
- Ask yourself: "Is this actually simpler, or did I just move complexity?"
- If the refactor made things harder to understand, reconsider.

$ARGUMENTS
