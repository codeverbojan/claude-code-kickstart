# Claude Code Kickstart — Reference Index

## Commands

| Command | Purpose |
|---------|---------|
| `/onboard` | Status check — read primer + gotchas, report, wait for instructions |
| `/onboard deep` | Full onboard — explore project, check health, deep report |
| `/onboard <task>` | Light onboard — focused on a specific task, start immediately |
| `/wrap-up` | End session — structured handoff to primer.md |
| `/fix <description>` | Bug fix playbook |
| `/feature <description>` | New feature playbook |
| `/refactor <description>` | Refactor playbook |
| `/api-route <description>` | API route playbook |
| `/research <question>` | Research-only playbook (no code) |
| `/init` | Auto-analyze codebase and generate CLAUDE.md Section 10 config |
| `/test` | Run full test suite |
| `/lint` | Run type-checker + linter + formatter |

## Agents

| Agent | Model | When |
|-------|-------|------|
| `code-reviewer` | Sonnet | After code changes |
| `security-reviewer` | Opus | API routes, auth, inputs |
| `accessibility-reviewer` | Sonnet | UI components |
| `test-runner` | Sonnet | Before commits |
| `researcher` | Sonnet | Investigation tasks |

## Session Flow

```
/onboard           → status → wait for task         (start of session)
/onboard <task>    → light context → start working   (focused work)
/onboard deep      → full context → plan → build     (major work)
/fix "bug desc"    → trace → fix → verify            (bug fix)
/research "topic"  → search → synthesize → report    (no code)
... work ...       → /test → /wrap-up                (end of session)
```

## Context Management

| Situation | Action |
|-----------|--------|
| New unrelated task | `/clear` |
| Context degrading | `/compact` |
| After 10+ messages | Re-read files before editing |
| Long research | Delegate to `researcher` agent |
| 5+ independent files | Launch parallel sub-agents |
| End of session | `/wrap-up` |
| Resume later | `claude --continue` |

## File Map

| File | Layer | Purpose |
|------|-------|---------|
| `CLAUDE.md` | 1 — Rules | Operating rules (always loaded) |
| `.claude/commands/` | 2 — Playbooks | Task-specific workflows |
| `.claude/agents/` | 2 — Agents | Specialized sub-agents |
| `.claude/skills/` | 3 — Reference | Domain knowledge |
| `CHEATSHEET.md` | 3 — Reference | This file — index |
| `primer.md` | 4 — Memory | Session state (auto-loaded) |
| `gotchas.md` | 4 — Memory | Mistake log (auto-loaded) |
