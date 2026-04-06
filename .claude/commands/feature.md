---
name: feature
description: New feature playbook — plan, build in phases, verify each phase
---

# New Feature Playbook

## 1. Understand
- Read `primer.md` for current state.
- Clarify requirements: what does "done" look like?
- If vague, outline what you'd build and where. Get approval first.

## 2. Plan
- List the files you'll create or modify.
- Break into phases if >5 files (max 5 files per phase).
- For non-trivial features: enter plan mode, write a spec, get approval.

## 3. Build (per phase)
- Create/edit only the files named in the plan.
- Follow existing project patterns — read similar code first.
- No over-engineering. Build what was asked, not what might be needed later.

## 4. Verify (per phase)
- Run type-checker
- Run linter
- Run tests
- Show passing output in this message. No skipping "because the last phase passed."
- Phase must compile and pass before moving to next phase.

## 5. Wrap
- Summarize what was built.
- Note any follow-up work or decisions deferred.
- Update `primer.md` if this was a significant feature.

$ARGUMENTS
