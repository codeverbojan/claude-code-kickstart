---
name: retrospective
description: Analyze captured mistake signals and auto-generate new gotcha rules
---

# Retrospective — Learn From Mistakes

Analyze `.claude/signals.jsonl` and generate new rules for `gotchas.md`.

## 1. Read Signals

Read `.claude/signals.jsonl`. Each line is a JSON object with:
- `timestamp`: when the signal was captured
- `type`: `revert`, `test_failure`, `lint_failure`, `typecheck_failure`
- `detail`: human-readable description
- `command`: the command that triggered the signal (secrets redacted)
- `snippet` (optional): first 500 chars of failure output — use this for root cause analysis

If the file doesn't exist or is empty, report "No signals captured yet. Work
on the project and mistakes will be automatically detected."

## 2. Group and Analyze

Group signals by type and look for patterns:
- **Repeated reverts on the same file** → something about that file's patterns isn't understood
- **Repeated test failures** → a testing pattern or convention is being missed
- **Repeated lint failures** → a linting rule keeps being violated
- **Repeated typecheck failures** → a type pattern isn't being followed

For each group, use the `snippet` field (when available) to identify the ROOT
CAUSE pattern. "Tests failed 5 times" is a symptom. "Form validation was
missing in 3 of 5 failures" is a pattern. If no snippet is available, group
by command pattern and flag which files/commands repeatedly trigger failures.

## 3. Read Existing Gotchas

Read `gotchas.md` to check what rules already exist. Do NOT create duplicate
rules. If an existing rule covers the pattern, skip it.

## 4. Generate New Rules

For each new pattern found, write a gotcha rule. Format:

```
N. [CATEGORY] Rule text — learned from [X signals over Y days]
```

Categories: `[REVERT]`, `[TEST]`, `[LINT]`, `[TYPECHECK]`

Rules should be:
- Actionable — tell Claude what TO DO, not just what went wrong
- Specific — reference actual file patterns, commands, or conventions
- Preventive — address the root cause, not the symptom

## 5. Append to gotchas.md

Append new rules under a `## Auto-generated` section at the end of `gotchas.md`.
If this section doesn't exist, create it. Find the highest existing rule number
in the file (manual or auto-generated) and continue from there. Never overwrite
or reorder existing rules.

After appending, re-read `gotchas.md` and verify the new rules are well-formed.
If anything looks corrupted, revert the change and report the issue.

## 6. Report

Show the user:
- How many signals were analyzed
- Signal breakdown by type
- How many new rules were generated
- The text of each new rule
- Signals that didn't produce rules (and why — already covered, one-off, etc.)

## 7. Offer to Clear

Ask the user: "Clear processed signals from .claude/signals.jsonl? [Y/n]"
If yes, truncate the file. If no, leave it for future analysis.

$ARGUMENTS
