---
name: wrap-up
description: End-of-session — structured handoff to primer.md
---

# Session Wrap-Up

## 1. Verify
- Run type-checker if any code changed
- Run linter if any code changed
- Run tests if any logic changed
- Note pass/fail status

## 2. Rewrite primer.md

Completely replace `primer.md` with this exact structure:

```markdown
# Session Primer

## Last Session
[Date or "today"]: [1-2 sentence summary of what was done]

## What Changed
- [file]: [what changed and why]
- [file]: [what changed and why]

## Current State
[What works, what doesn't, what's partially done]

## Uncommitted Changes
- [List any staged/unstaged changes, or "None — all committed"]

## Test Status
- Type-check: PASS/FAIL/NOT CONFIGURED
- Lint: PASS/FAIL/NOT CONFIGURED
- Tests: PASS/FAIL/NOT CONFIGURED (X passed, Y failed)

## Decisions Made
- [Any choices between alternatives and why, or "None"]

## Risks
- [Anything fragile, incomplete, or needing attention]

## Next Steps
1. [Specific, actionable next step]
2. [Specific, actionable next step]
3. [Specific, actionable next step]

## Next Recommended Command
[The exact slash command to run next session, e.g. "/onboard deep finish the auth system"]

## Key Files
- [Files the next session should read first]
```

## 3. Update decisions.md (if decisions were made)

If any technical decisions, architecture choices, or tradeoff judgments were
made this session, APPEND them to `decisions.md`. Never overwrite existing entries.

Format for each new decision:
```markdown
## [Date]: [Short title]
**Choice:** [What was decided]
**Why:** [The reasoning — constraints, tradeoffs, alternatives rejected]
**Context:** [What prompted this decision]
```

Before appending, check if a decision with the same title already exists in
decisions.md. If it does, skip it (don't create duplicates).

Only log decisions that a future session would need to know about.
Don't log trivial choices (variable names, formatting). Log choices that
would be re-litigated if someone didn't know the reasoning:
- Technology/library choices
- Architecture decisions
- Pattern decisions (why X approach over Y)
- Scope decisions (why something was deferred or cut)

## 4. Update gotchas.md (if needed)
If any mistakes were made this session, append a numbered rule.

## 5. Append session metrics

Append one JSON line to `.claude/metrics.jsonl` with this session's stats:

```json
{
  "date": "YYYY-MM-DD",
  "files_touched": 0,
  "verification_runs": 0,
  "gotchas_added": 0,
  "signals_captured": 0,
  "decisions_logged": 0
}
```

Get counts from deterministic sources (not from memory — compaction loses history):
- `files_touched`: run `git diff --name-only | wc -l` (or `git diff --cached --name-only | wc -l`)
- `verification_runs`: best-effort count from this conversation (may undercount after compaction)
- `gotchas_added`: count new rules you added to gotchas.md (0 if none)
- `signals_captured`: run `grep -c "$(date -u +%Y-%m-%d)" .claude/signals.jsonl 2>/dev/null || echo 0`
- `decisions_logged`: count decisions you appended to decisions.md (0 if none)

Write the JSON line with a Bash command: `echo '{"date":"...","files_touched":N,...}' >> .claude/metrics.jsonl`

## 6. Report to user
- One-paragraph summary of the session
- Any uncommitted changes needing attention
- Any failing checks

$ARGUMENTS
