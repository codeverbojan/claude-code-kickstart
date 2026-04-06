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

## 3. Update gotchas.md (if needed)
If any mistakes were made this session, append a numbered rule.

## 4. Report to user
- One-paragraph summary of the session
- Any uncommitted changes needing attention
- Any failing checks

$ARGUMENTS
