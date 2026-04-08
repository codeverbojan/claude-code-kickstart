---
name: wrap-up
description: End-of-session — structured handoff to primer.md
---

# Session Wrap-Up

## 1. Verify
Run typecheck/lint/tests if any code changed. Note pass/fail. Skip if nothing
was touched.

## 2. Rewrite primer.md

Overwrite `primer.md` with exactly this structure (replace bracketed hints):

```markdown
# Session Primer

## Last Session
[date]: [1–2 sentence summary]

## What Changed
- [file]: [why]

## Current State
[what works, what doesn't, what's partial]

## Uncommitted Changes
[list, or "None"]

## Test Status
- Type-check: PASS | FAIL | NOT CONFIGURED
- Lint: PASS | FAIL | NOT CONFIGURED
- Tests: PASS | FAIL | NOT CONFIGURED (X passed, Y failed)

## Decisions Made
[bullets, or "None"]

## Risks
[fragile or incomplete bits]

## Next Steps
1. [actionable]
2. [actionable]

## Next Recommended Command
[exact slash command, e.g. `/onboard deep finish auth`]

## Key Files
- [files next session should read first]
```

## 3. Append to decisions.md (only if real decisions were made)

Append new entries — never overwrite. Skip trivial choices (naming, formatting).
Log choices that would be re-litigated without context: tech picks, architecture,
pattern decisions, scope cuts. Skip if a matching title already exists.

Format:
```markdown
## [date]: [title]
**Choice:** …
**Why:** …
**Context:** …
```

## 4. Append to gotchas.md (only if mistakes happened)
Numbered rule per mistake. Skip if none.

## 5. Append metrics line

```bash
echo '{"date":"YYYY-MM-DD","files_touched":N,"verification_runs":N,"gotchas_added":N,"signals_captured":N,"decisions_logged":N}' >> .claude/metrics.jsonl
```

Counts (deterministic — don't guess from memory):
- `files_touched`: `git diff --name-only | wc -l`
- `signals_captured`: `grep -c "$(date -u +%Y-%m-%d)" .claude/signals.jsonl 2>/dev/null || echo 0`
- Others: count what you actually added this session.

## 6. Report
One paragraph: what shipped, uncommitted changes, failing checks. No epic
summary — the user will read primer.md.

$ARGUMENTS
