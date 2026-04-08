---
name: feature
description: New feature playbook — plan, build in phases, verify each phase
---

# New Feature Playbook

This playbook runs under CLAUDE.md §4 Execution Loop: one phase at a time,
parallel review agents at each checkpoint, per-checkpoint report format.

## 1. Understand
- Read `primer.md` for current state (if not already in context).
- Clarify requirements: what does "done" look like? Inputs, outputs, edge
  cases, failure modes.
- If vague, outline what you'd build and where. Get approval before coding.

## 2. Plan
- List the files you'll create or modify, grouped by phase.
- Max 5 files per phase. Each phase is independently shippable.
- For non-trivial features (3+ steps or architectural decisions): enter plan
  mode, write a spec, get approval before writing code.
- Capture the intended behavior in one paragraph — this is what review agents
  will check against.

## 3. Build + test one phase at a time
Per CLAUDE.md §4:
- Implement the phase. Keep scope to the named files.
- Write tests in the same turn — not as a follow-up.
- Follow existing project patterns; read similar code first.
- For non-trivial code exploration, prefer SocratiCode MCP tools over raw grep.
- No speculative abstractions. Build what was asked.

## 4. Checkpoint review (mandatory, in parallel)
After each phase, spawn review agents in a single message:
- `code-reviewer` — spec compliance + quality
- `security-reviewer` — if the phase touches auth, inputs, DB queries, or APIs
- `test-runner` — run the suite, report results
- `accessibility-reviewer` — if the phase touches UI

Every reviewer must receive: the task description, the intended behavior
paragraph from step 2, and the list of files in this phase. A reviewer
without intent cannot judge correctness.

Fix all valid findings before starting the next phase. For any finding you
dispute, state why in one sentence.

## 5. Report (per phase — use the §4 format)
```
Task: <phase name>
Implementation: <files touched, approach>
Tests: <what was tested, pass/fail counts>
Review findings: <bullets from each reviewer, or "clean">
Fixes: <what changed, or "none">
Status: <complete | blocked: reason>
```

## 6. Wrap
- Summarize what was built across all phases.
- Note any follow-up work or deferred decisions.
- Update `primer.md` if this was a significant feature.

$ARGUMENTS
