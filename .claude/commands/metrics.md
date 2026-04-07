---
name: metrics
description: Show session metrics and improvement trends from .claude/metrics.jsonl
---

# Session Metrics

Read `.claude/metrics.jsonl` and show trends.

## 1. Read Data

Read `.claude/metrics.jsonl`. Each line is a JSON object with:
- `date`, `files_touched`, `verification_runs`, `gotchas_added`,
  `signals_captured`, `decisions_logged`

If the file doesn't exist or is empty, report "No metrics yet. Run /wrap-up
to start tracking session stats."

## 2. Show Summary

Display a table of the last 10 sessions:

```
Date        Files  Verified  Gotchas  Signals  Decisions
2026-04-01    5       3         1        2         1
2026-04-02    8       4         0        0         2
...
```

## 3. Show Trends

If fewer than 5 sessions, show the table but skip trend analysis. Instead say:
"Not enough data for trends yet (N sessions). Need at least 5."

With 5+ sessions, calculate and display:
- **Average files per session** (are sessions getting bigger or smaller?)
- **Verification ratio** (verification_runs / files_touched — are you verifying enough?)
- **Signal trend** (are signals decreasing over time? = fewer mistakes)
- **Gotcha growth** (total gotchas accumulated — the system's learned knowledge)

## 4. Insights

Based on the data, provide 1-2 actionable insights:
- If signals are increasing: "Mistake rate is rising. Consider running /retrospective."
- If verification ratio is low: "You're editing more than verifying. Run tests more often."
- If signals are decreasing: "Fewer mistakes over time — the gotchas are working."
- If no signals in last 5 sessions: "Clean streak — no mistakes detected in 5 sessions."

$ARGUMENTS
