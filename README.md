# Claude Code Kickstart

Production-grade agentic workflow template for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Drop into any project. Get session memory, sub-agents, task playbooks, and structured handoffs.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed (`npm install -g @anthropic-ai/claude-code`)
- Git
- A project (or start fresh)

## Install

Run this in your project root:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh)
```

The interactive wizard asks:
1. **Stack** — Node/TypeScript, Python, Go, Rust, or Other
2. **Package manager** — pnpm, npm, yarn, bun (for Node)
3. **Commands** — dev, typecheck, lint, test, build (pre-filled with smart defaults)
4. **Conventions** — any rules to enforce

It then auto-configures CLAUDE.md, settings.json permissions, and worktree symlinks for your stack.

Skip the wizard with `--skip-wizard`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh) --skip-wizard
```

Or clone and run manually:

```bash
git clone https://github.com/codeverbojan/claude-code-kickstart.git /tmp/cck
bash /tmp/cck/install.sh /path/to/your/project
```

Never overwrites existing files. Safe on any project.

## Architecture: 4 Layers

```
Layer 1 — CLAUDE.md          Strict operating rules. Always loaded. ~140 lines.
Layer 2 — Commands + Agents   Task playbooks + specialized sub-agents.
Layer 3 — Skills + Cheatsheet Domain knowledge + reference index.
Layer 4 — primer.md + gotchas Session memory. Auto-loaded via hook.
```

Claude only loads what it needs. Small fixes don't pay the cost of full onboarding.

## Your First 5 Minutes

### 1. Run the installer

The wizard configures your stack, commands, and conventions automatically.
To fine-tune further, edit `CLAUDE.md` Section 10 directly.

### 2. Start Claude

```bash
claude
```

Session hook auto-loads `primer.md` + `gotchas.md`.

### 3. Pick a workflow

```bash
/onboard              # status check — report and wait
/onboard deep         # full context load for major work
/fix login crash      # bug fix playbook
/feature user auth    # new feature playbook
/research best ORM    # research only, no code
```

### 4. End your session

```bash
/wrap-up
```

Writes a structured handoff to `primer.md` with: what changed, test status, decisions, risks, next steps. Next session picks up exactly where you left off.

## What Gets Installed

```
your-project/
├── CLAUDE.md                    <- Layer 1: Operating rules (customize!)
├── primer.md                    <- Layer 4: Session state (auto-loaded)
├── gotchas.md                   <- Layer 4: Mistake log (auto-loaded)
├── CHEATSHEET.md                <- Layer 3: Reference index
├── .claudeignore
├── .worktreeinclude
└── .claude/
    ├── settings.json            <- Hooks, permissions, worktree config
    ├── mcp.json                 <- MCP servers (Playwright + Context7)
    ├── agents/                  <- Layer 2: Sub-agents
    │   ├── code-reviewer.md
    │   ├── security-reviewer.md
    │   ├── accessibility-reviewer.md
    │   ├── test-runner.md
    │   └── researcher.md
    ├── commands/                <- Layer 2: Task playbooks
    │   ├── onboard.md           /onboard [deep] [task]
    │   ├── wrap-up.md           /wrap-up
    │   ├── fix.md               /fix <bug description>
    │   ├── feature.md           /feature <feature description>
    │   ├── refactor.md          /refactor <what and why>
    │   ├── api-route.md         /api-route <endpoint>
    │   ├── research.md          /research <question>
    │   ├── test.md              /test
    │   └── lint.md              /lint
    └── skills/                  <- Layer 3: Domain knowledge
        ├── securing-code/
        └── running-tests/
```

## Commands

### Session
| Command | Purpose |
|---------|---------|
| `/onboard` | Status check — read context, report, wait for instructions |
| `/onboard deep` | Full onboard — explore project, check health, deep report |
| `/onboard <task>` | Light onboard — focused on a task, start immediately |
| `/wrap-up` | Structured handoff — saves state for next session |

### Task Playbooks
| Command | Purpose |
|---------|---------|
| `/fix` | Bug fix: trace, scope, fix, verify, document |
| `/feature` | New feature: plan, build in phases, verify each phase |
| `/refactor` | Refactor: scope, delete dead code, restructure, verify |
| `/api-route` | API route: auth, validate, query, respond, security check |
| `/research` | Research only: investigate, synthesize, no code |

### Verification
| Command | Purpose |
|---------|---------|
| `/test` | Run full test suite |
| `/lint` | Run type-checker + linter + formatter |

## Sub-Agents

| Agent | Model | When Used |
|-------|-------|-----------|
| `code-reviewer` | Sonnet | After code changes |
| `security-reviewer` | **Opus** | API routes, auth, inputs, supply chain |
| `accessibility-reviewer` | Sonnet | Any UI component |
| `test-runner` | Sonnet | Before commits |
| `researcher` | Sonnet | Investigation tasks |

Invoked automatically or explicitly:
```
Use the security-reviewer agent to audit the auth module
Use the researcher agent to compare ORMs
```

## How Session Memory Works

```
Session Start
  |
Hook loads primer.md + gotchas.md
  |
Claude knows: last session state, next steps, mistakes to avoid
  |
Work (with playbooks, sub-agents, verification)
  |
/wrap-up writes structured handoff:
  - What changed (files + reasons)
  - Uncommitted changes
  - Test status
  - Decisions made + rationale
  - Risks
  - Next steps + recommended command
  |
Next session resumes cleanly
```

## Customization

### Add an agent
```yaml
# .claude/agents/my-agent.md
---
name: my-agent
description: What it does
tools: Read, Grep, Glob, Bash
model: sonnet
effort: medium
---
Instructions...
```

### Add a command
```yaml
# .claude/commands/deploy.md
---
name: deploy
description: Deploy to staging
---
Steps to execute...
$ARGUMENTS
```

### Add a skill
```yaml
# .claude/skills/my-domain/SKILL.md
---
name: my-domain
description: When to use
---
Domain knowledge...
```

### Adjust permissions
Edit `.claude/settings.json` — add/remove allowed bash commands.

### Add MCP servers
Edit `.claude/mcp.json`:
```json
{
  "mcpServers": {
    "postgres": { "command": "npx", "args": ["-y", "@modelcontextprotocol/server-postgres", "postgresql://localhost/mydb"] }
  }
}
```

## Recommended Add-ons

### SocratiCode (large codebases)

If your project is 100k+ lines or a monorepo, add [SocratiCode](https://github.com/giancarloerra/SocratiCode) for semantic code search, dependency graphs, and context artifacts. Requires Docker.

Install as a Claude Code plugin:
```bash
claude plugin marketplace add giancarloerra/socraticode
claude plugin install socraticode@socraticode
```

Or as MCP server only:
```bash
claude mcp add socraticode -- npx -y socraticode
```

Not included by default because it requires Docker and adds overhead that small/medium projects don't need. For large codebases, it's a significant upgrade over grep-based search.

## Key Patterns

1. **Layered architecture** — Rules / Playbooks / Reference / Memory. Only load what's needed.
2. **Task playbooks** — `/fix`, `/feature`, `/refactor`, `/research` — right behavior instantly.
3. **Tiered onboarding** — Bare `/onboard` = status. With task = light. With `deep` = full.
4. **Structured handoffs** — `/wrap-up` produces standard format, not freeform text.
5. **Mistake memory** — `gotchas.md` ensures errors never repeat across sessions.
6. **Forced verification with proof** — Tests must pass AND show output before "Done!"
7. **Anti-rationalization** — Playbooks explicitly block common excuses for skipping steps.
8. **Two-stage code review** — Spec compliance first, then code quality. Separate passes.
9. **Sub-agent swarming** — Parallel agents for large tasks.
10. **Latest version enforcement** — Always current packages, never outdated.

## FAQ

**Works with any language?** Yes. Language-agnostic. Customize Section 10 of CLAUDE.md.

**Slows down Claude?** No. Hook loads two small files. Agents launch only when needed.

**Existing project?** Yes. Installer never overwrites. Copies individual files.

**Already have CLAUDE.md?** Installer skips it. Merge manually.

**Need Opus?** Only `security-reviewer` uses Opus. Everything else uses Sonnet. Change any agent's model in its `.md` file.

## License

MIT
