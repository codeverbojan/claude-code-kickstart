# Claude Code Kickstart

Production-grade agentic workflow template for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Drop into any project. Get session memory, sub-agents, task playbooks, and structured handoffs.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed:
  - macOS, Linux, WSL: `curl -fsSL https://claude.ai/install.sh | bash`
  - Windows PowerShell: `irm https://claude.ai/install.ps1 | iex`
- Git
- A project (or start fresh — click **"Use this template"** on GitHub)

## Install

**For existing projects** — run in your project root:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh)
```

The installer auto-detects your stack from project files (`package.json`, `go.mod`, `Cargo.toml`, `pyproject.toml`), reads your actual commands from `package.json` scripts or `Makefile` targets, and offers framework-specific starter configs (Next.js, FastAPI, Go API, Rust CLI). You confirm and optionally add conventions — that's it.

**Update existing install** (preserves your CLAUDE.md, primer.md, gotchas.md, settings.json):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh) --update
```

**Skip wizard:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh) --skip-wizard
```

**Windows:** Use WSL or Git Bash to run the installer.

Never overwrites existing files on fresh install. Safe on any project.

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

Auto-detects your stack and offers a matching starter config.
To fine-tune later, run `/init` inside Claude Code or edit `CLAUDE.md` Section 10.

### 2. Start Claude

```bash
claude
```

Session hook auto-loads `primer.md` + `gotchas.md`.

### 3. Pick a workflow

```bash
/onboard              # status check — report and wait
/onboard deep         # full context load for major work
/init                 # auto-analyze codebase, generate project config
/fix login crash      # bug fix playbook
/feature user auth    # new feature playbook
/research best ORM    # research only, no code
```

### 4. End your session

```bash
/wrap-up
```

Writes a structured handoff to `primer.md`. Next session picks up exactly where you left off.

## What Gets Installed

```
your-project/
├── CLAUDE.md                    <- Layer 1: Operating rules (customize!)
├── primer.md                    <- Layer 4: Session state (auto-loaded)
├── gotchas.md                   <- Layer 4: Mistake log (auto-loaded)
├── CHEATSHEET.md                <- Layer 3: Reference index
├── .claudeignore
├── .worktreeinclude
├── .npmrc                       <- Supply chain guards (Node.js only)
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
    │   ├── init.md              /init (auto-analyze codebase)
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
| `/init` | Auto-analyze codebase and generate CLAUDE.md Section 10 config |

### Task Playbooks
| Command | Purpose |
|---------|---------|
| `/fix` | Bug fix: trace root cause, scope, fix, verify, document |
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
| `code-reviewer` | Sonnet | After code changes (two-stage: spec compliance + quality) |
| `security-reviewer` | **Opus** | API routes, auth, inputs, supply chain |
| `accessibility-reviewer` | Sonnet | Any UI component (WCAG 2.1 AA) |
| `test-runner` | Sonnet | Before commits |
| `researcher` | Sonnet | Investigation tasks |

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
  - Test status, decisions, risks
  - Next steps + recommended command
  |
Next session resumes cleanly
```

## Updating

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh) --update
```

Updates agents, commands, skills, and CHEATSHEET to the latest version. Preserves your customized files: CLAUDE.md, primer.md, gotchas.md, settings.json, mcp.json. Your custom agents/commands are not deleted.

## Starter Configs

The installer detects your framework and offers a pre-built Section 10 config:

| Framework | Detection | Starter |
|-----------|-----------|---------|
| Next.js | `"next"` in package.json | Conventions, App Router architecture |
| FastAPI | `fastapi` in pyproject.toml | Pydantic, Alembic, async patterns |
| Go API | Router in go.mod (chi, gin, echo) | Handler/service/repo layers |
| Rust CLI | `clap` in Cargo.toml | thiserror/anyhow, clippy::pedantic |

Don't see your stack? Run `/init` after installing — it analyzes your actual codebase and generates a custom config.

## Recommended Add-ons

### SocratiCode (large codebases)

For 100k+ line projects or monorepos, add [SocratiCode](https://github.com/giancarloerra/SocratiCode) for semantic code search, dependency graphs, and context artifacts. Requires Docker.

```bash
claude plugin marketplace add giancarloerra/socraticode
claude plugin install socraticode@socraticode
```

## Key Patterns

1. **Layered architecture** — Rules / Playbooks / Reference / Memory. Only load what's needed.
2. **Auto-detection** — Installer reads project files, not just asks questions.
3. **Task playbooks** — `/fix`, `/feature`, `/refactor`, `/research` — right behavior instantly.
4. **Tiered onboarding** — Bare `/onboard` = status. With task = light. With `deep` = full.
5. **Structured handoffs** — `/wrap-up` produces standard format, not freeform text.
6. **Mistake memory** — `gotchas.md` ensures errors never repeat across sessions.
7. **Forced verification with proof** — Tests must pass AND show output before "Done!"
8. **Anti-rationalization** — Playbooks explicitly block common excuses for skipping steps.
9. **Two-stage code review** — Spec compliance first, then code quality.
10. **Supply chain guards** — `.npmrc` with `ignore-scripts`, 7-day soak period, pinned versions.
11. **Updatable** — `--update` pulls latest without touching your config.

## FAQ

**Works with any language?** Yes. Language-agnostic. The installer supports Node, Python, Go, Rust out of the box. For others, run `/init` to auto-configure.

**Slows down Claude?** No. Hook loads two small files. Agents launch only when needed.

**Existing project?** Yes. Installer never overwrites. Copies individual files.

**Already have CLAUDE.md?** Installer skips it. Run `/init` to add Section 10, or merge manually.

**Windows?** Use WSL or Git Bash to run the installer.

**How do I update?** `bash <(curl ...) --update`. Preserves your config, updates everything else.

**Need Opus?** Only `security-reviewer` uses Opus. Everything else uses Sonnet. Change any agent's model in its `.md` file.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add playbooks, starters, agents, and skills.

## License

MIT
