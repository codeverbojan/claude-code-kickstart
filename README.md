# Claude Code Kickstart

Production-grade agentic workflow template for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Drop into any project. Get session memory, sub-agents, task playbooks, and structured handoffs.

![Demo](demo.gif)

**One-line install:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh)
```

> 📖 **Read the story:** [I Built a Self-Improving Workflow for Claude Code](https://bojanjosifoski.com/i-built-a-self-improving-workflow-for-claude-code/) — the why, the four layers, and the self-improving loop that makes this different from every other CLAUDE.md template.

## The self-improving loop

This is what makes Kickstart different. Every other template is static. This one learns from its own mistakes:

```
  Mistake happens                           ┐
         │                                   │
         ▼                                   │
  PostToolUse hook captures the signal       │
  (git reverts, test/lint failures)          │
         │                                   │  Auto-loop.
         ▼                                   │  You do
  /retrospective groups signals →            │  nothing.
  appends new rules to gotchas.md            │
         │                                   │
         ▼                                   │
  SessionStart hook auto-loads gotchas       │
  at every new session                       │
         │                                   │
         ▼                                   │
  Claude avoids the same category of bug    ┘
         │
         ▼
  /metrics shows mistake rate trending down over time
```

Five hooks enforce it. `SessionStart` loads memory. `UserPromptSubmit` coaches habits. `Stop` blocks unverified "Done" claims. `PreToolUse` forces file re-reads before edits. `PostToolUse` captures mistake signals asynchronously. See [`.claude/settings.json`](.claude/settings.json) for the wiring.

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

**Update existing install** (preserves your CLAUDE.md, primer.md, gotchas.md, patterns.md, decisions.md, settings.json):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh) --update
```

**Skip wizard:**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh) --skip-wizard
```

**Windows:** Use WSL or Git Bash to run the installer.

**Track distribution channel** (for maintainers sharing the install link across platforms):

```bash
# Tag the install source — recorded to .claude/install-source.txt in the target project
CCK_SRC=twitter bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh)
# or as a flag:
bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh) --src=linkedin
```

Share one unique snippet per channel (Twitter, LinkedIn, blog post, Discord, etc.) and each installed project will carry its origin in `.claude/install-source.txt`.

Never overwrites existing files on fresh install. Safe on any project.

## Architecture: 4 Layers

```
Layer 1 — CLAUDE.md          Strict operating rules. Always loaded.
Layer 2 — Commands + Agents   Task playbooks + specialized sub-agents.
Layer 3 — Skills + Cheatsheet Domain knowledge + reference index.
Layer 4 — Memory files        primer, gotchas, patterns, decisions. Auto-loaded via hook.
```

Claude only loads what it needs. Small fixes don't pay the cost of full onboarding.

## Your First 5 Minutes

### 1. Run the installer

Auto-detects your stack and offers a matching starter config.
To fine-tune later, run `/init` or `/learn` inside Claude Code, or edit `CLAUDE.md` Section 10.

### 2. Start Claude

```bash
claude
```

Session hook auto-loads `primer.md` plus any of `gotchas.md`, `patterns.md`, `decisions.md` that have real content (template stubs are skipped), and shows git commits since the last session.

### 3. Pick a workflow

```bash
/onboard              # status check — report and wait
/onboard deep         # full context load for major work
/init                 # auto-analyze codebase, generate project config
/learn                # extract real code patterns into patterns.md
/fix login crash      # bug fix playbook
/feature user auth    # new feature playbook
/research best ORM    # research only, no code
```

### 4. End your session

```bash
/wrap-up
```

Writes a structured handoff to `primer.md`, logs decisions to `decisions.md`. Next session picks up exactly where you left off.

## What Gets Installed

```
your-project/
├── CLAUDE.md                    <- Layer 1: Operating rules (customize!)
├── primer.md                    <- Layer 4: Session state (auto-loaded)
├── gotchas.md                   <- Layer 4: Mistake log (auto-loaded)
├── patterns.md                  <- Layer 4: Code patterns (auto-loaded, populated by /learn)
├── decisions.md                 <- Layer 4: Decision log (auto-loaded, updated by /wrap-up)
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
    ├── hooks/                   <- Automated behavior scripts
    │   ├── session-primer.sh    SessionStart — loads primer + non-stub memory
    │   ├── verify-gate.sh       Stop — blocks code edits without test output
    │   ├── habits-coach.sh      UserPromptSubmit — nudges toward playbooks
    │   └── capture-signal.sh    PostToolUse — records reverts/failures async
    ├── commands/                <- Layer 2: Task playbooks (14 commands)
    │   ├── onboard.md           /onboard [deep] [task]
    │   ├── wrap-up.md           /wrap-up (+ metrics + decisions)
    │   ├── reset.md             /reset (wrap-up + clear + deep onboard)
    │   ├── init.md              /init (auto-analyze codebase)
    │   ├── learn.md             /learn (extract patterns)
    │   ├── retrospective.md     /retrospective (auto-generate gotchas)
    │   ├── metrics.md           /metrics (show improvement trends)
    │   ├── fix.md               /fix <bug description>
    │   ├── feature.md           /feature <feature description>
    │   ├── refactor.md          /refactor <what and why>
    │   ├── api-route.md         /api-route <endpoint>
    │   ├── research.md          /research <question>
    │   ├── test.md              /test
    │   ├── lint.md              /lint
    │   └── security-review.md   /security-review (preflight + diff audit)
    └── skills/                  <- Layer 3: Domain knowledge
        ├── securing-code/
        └── running-tests/
```

## Commands

### Session & Knowledge
| Command | Purpose |
|---------|---------|
| `/onboard` | Status check — read context, report, wait for instructions |
| `/onboard deep` | Full onboard — explore project, check health, deep report |
| `/onboard <task>` | Light onboard — focused on a task, start immediately |
| `/wrap-up` | Structured handoff — saves state + decisions + metrics for next session |
| `/reset` | Wrap up + clear context + deep onboard in one step (fresh start) |
| `/init` | Auto-analyze codebase and generate CLAUDE.md Section 10 config |
| `/learn` | Extract real code patterns into patterns.md (auto-loaded each session) |
| `/retrospective` | Analyze captured mistake signals, auto-generate new gotcha rules |
| `/metrics` | Show per-session stats and improvement trends |

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
| `/security-review` | Audit diff vs `origin/HEAD` — pre-flights git state with actionable errors |

## Sub-Agents

| Agent | Model | When Used |
|-------|-------|-----------|
| `code-reviewer` | Sonnet | After code changes (two-stage: spec compliance + quality) |
| `security-reviewer` | **Opus** | API routes, auth, inputs, supply chain |
| `accessibility-reviewer` | Haiku | Any UI component (WCAG 2.1 AA) |
| `test-runner` | Haiku | Before commits |
| `researcher` | Haiku | Investigation tasks (web search, codebase exploration) |

## Hooks (Automated Enforcement)

Five hooks enforce discipline without you having to remind Claude:

| Hook | Type | What it does |
|------|------|-------------|
| **SessionStart** | command | Loads primer.md + recent git history. Skips `gotchas.md`/`patterns.md`/`decisions.md` when they're still template stubs (zero-cost on fresh installs). |
| **UserPromptSubmit** | command | Habits coach — nudges user toward playbooks and `/wrap-up` (shown to user, not Claude) |
| **Stop** | command | Verification gate (pure bash, sub-100ms). Inspects last turn; only blocks if code was edited without showing test/lint/typecheck output. Zero LLM cost on conversational/research/docs turns. |
| **PreToolUse(Edit\|Write)** | command | Injects reminder to re-read the file before editing (via `additionalContext`) |
| **PostToolUse(Bash)** | command (async) | Captures mistake signals: git reverts, test/lint/typecheck failures → `.claude/signals.jsonl` |

### Model defaults

- **Main session:** `opusplan` (Opus during planning, Sonnet during execution — the cost/quality sweet spot). Override in `.claude/settings.json` if you want plain Sonnet or Opus.
- **Sub-agents:** `security-reviewer` on Opus; `code-reviewer` on Sonnet; `test-runner`, `researcher`, `accessibility-reviewer` on Haiku 4.5 with `effort: low`.

## Self-Improving System

The template gets smarter over time — without you doing anything:

```
PostToolUse hook captures signals automatically
  (git reverts, test failures, lint failures)
        |
        v
.claude/signals.jsonl accumulates mistake data
  (with failure snippets for root cause analysis)
        |
        v
/retrospective analyzes signals → auto-generates gotcha rules
  (grouped by type, deduplicated, confidence-scored)
        |
        v
gotchas.md grows with learned rules
  (auto-loaded every session via hook)
        |
        v
Claude avoids the same category of mistake next time
```

Run `/retrospective` periodically (weekly or after a rough session). Run `/metrics` to see if mistake rates are decreasing over time.

## How Session Memory Works

```
Session Start
  |
Hook loads: primer.md (+ gotchas/patterns/decisions if non-stub)
  + git commits since last session
  |
Claude knows: project state, mistakes to avoid, code patterns,
  settled decisions, what changed between sessions
  |
Work (with playbooks, sub-agents, verification)
  |
/wrap-up writes structured handoff:
  - What changed (files + reasons)
  - Uncommitted changes
  - Test status, decisions made, risks
  - Next steps + recommended command
  |
Next session resumes cleanly
```

## Updating

```bash
# Update agents, commands, skills, hooks, CHEATSHEET — preserve your config
bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh) --update

# Re-run the wizard against an existing install (regenerates Section 10/11 only)
bash setup.sh --reconfigure

# See what would be installed without touching any files
bash setup.sh --dry-run
```

`--update` preserves CLAUDE.md, primer.md, gotchas.md, patterns.md, decisions.md, settings.json, and mcp.json. It refreshes agents, commands, skills, hooks, and CHEATSHEET. When it detects a Section 10/11 generated by an older wizard schema, it prints a warning pointing you at `--reconfigure`.

`--reconfigure` preserves all other content and only regenerates the Project-Specific Configuration section. A `CLAUDE.md.bak` is written before the destructive edit.

## Wizard flags

| Flag | Purpose |
|---|---|
| `--skip-wizard` | Non-interactive install; auto-detects stack |
| `--update` | Refresh template files; preserve user config; warn on stale schema |
| `--reconfigure` | Re-run wizard only; regenerate Section 10/11 in place |
| `--dry-run` / `--preview` | Run detection + validation; exit without writing |
| `--style=concise\|balanced\|beginner` | Non-interactive response-style selection |
| `--advanced` | Unlock power-user interactive menu |
| `--model=opusplan\|sonnet\|opus\|haiku` | Override main session model |
| `--no-mcp` | Skip .claude/mcp.json install |
| `--no-section` | Skip CLAUDE.md Section 10/11 replacement |
| `--skip-agents=a,b,c` | Omit specific sub-agents (comma-separated) |

## Auto-detected stacks

The wizard detects 14+ stacks out of the box with sensible command defaults:

| Stack | Detection marker | Framework-specific detection |
|---|---|---|
| Node.js / TypeScript | `package.json` | Next.js, Remix, SvelteKit, Astro, Nuxt, Vite+React/Vue |
| Python | `pyproject.toml` / `requirements.txt` / `setup.py` | FastAPI, Django, Flask, LangChain/LLM projects |
| Go | `go.mod` | chi / gin / echo / fiber |
| Rust | `Cargo.toml` | clap (CLI), other binary crates |
| Deno | `deno.json` / `deno.jsonc` | — |
| Bun | `bun.lockb` without package.json | — |
| Elixir | `mix.exs` | Phoenix |
| Ruby | `Gemfile` | Rails / Sinatra |
| Java / Kotlin | `pom.xml` / `build.gradle` / `build.gradle.kts` | Spring Boot |
| .NET / C# | `*.csproj` / `*.sln` | ASP.NET |
| PHP | `composer.json` | Laravel / Symfony |
| Make-driven | `Makefile` / `makefile` | autodetects dev/test/lint/build targets |

Orthogonal flags: **monorepo** detection (Turborepo, Nx, Lerna, pnpm workspaces) and **CODEOWNERS** detection both append notes to Section 10/11.

For Next.js, FastAPI, Go API, and Rust CLI there are also pre-built starter configs in `starters/`. Other detected stacks get an auto-generated Section 10/11 populated from the detected commands.

Don't see your stack? Run `/init` after installing — it analyzes your actual codebase and generates a custom config.

## Substantive questions (optional)

On fresh installs, the wizard asks a single master toggle: "Answer 5 quick questions about DB / auth / deploy / secrets?" (default N). If you opt in, it asks about:

1. **Database** — Postgres / MySQL / SQLite / MongoDB / DynamoDB / Redis / Other
2. **Auth** — NextAuth / Clerk / Auth0 / Supabase / Cognito / Custom JWT / Session cookies
3. **Deployment target** — Vercel / Railway / Fly.io / AWS / GCP / Azure / Self-hosted
4. **Does this project call LLMs?** (Anthropic / OpenAI / LangChain)
5. **Secret management** — .env file / platform env vars / Vault / AWS Secrets Manager / Doppler

Each answer feeds an `### Infrastructure` subsection in CLAUDE.md that reviewers use to calibrate severity — e.g. SQL injection matters differently for Postgres vs. DynamoDB.

## Recommended Add-ons

### SocratiCode (large codebases)

For 100k+ line projects or monorepos, add [SocratiCode](https://github.com/giancarloerra/SocratiCode) for semantic code search, dependency graphs, and context artifacts. Requires Docker.

The installer auto-detects codebases with >500 source files and prints an install reminder at the end of the wizard. CLAUDE.md §4 already references SocratiCode tools (`codebase_search`, `codebase_graph_query`) for non-trivial code exploration inside the `/feature` and `/fix` playbooks.

```bash
claude plugin marketplace add giancarloerra/socraticode
claude plugin install socraticode@socraticode
```

## Key Patterns

1. **Layered architecture** — Rules / Playbooks / Reference / Memory. Only load what's needed.
2. **Auto-detection** — Installer reads project files, not just asks questions.
3. **Project intelligence** — `/learn` extracts real patterns, `decisions.md` preserves WHY.
4. **Git-aware sessions** — Hook shows commits since last session on startup.
5. **Task playbooks** — `/fix`, `/feature`, `/refactor`, `/research` — right behavior instantly.
6. **Tiered onboarding** — On fresh installs, skip `/onboard` entirely. With a task = light mode. With `deep` = full context load once `gotchas`/`patterns`/`decisions` have real content.
7. **Structured handoffs** — `/wrap-up` produces standard format with decisions and risks.
8. **Self-improving** — Hooks auto-capture mistakes, `/retrospective` generates gotcha rules, `/metrics` tracks improvement.
9. **Mistake memory** — `gotchas.md` grows automatically over time, auto-loaded every session.
10. **Hook enforcement** — Stop hook blocks unverified claims. PostToolUse captures failure signals async.
11. **User coaching** — Habits coach nudges users toward playbooks, onboarding, and wrap-ups.
12. **Anti-rationalization** — Playbooks explicitly block common excuses for skipping steps.
13. **Two-stage code review** — Spec compliance first, then code quality.
14. **Supply chain guards** — `.npmrc` with `ignore-scripts`, 7-day soak period, pinned versions.
15. **Updatable** — `--update` pulls latest without touching your config. `--reconfigure` re-runs the wizard in place. `--dry-run` previews without writing. Version-stamped Section 10/11 lets `--update` warn when new wizard questions are available.
16. **Smart merge** — Existing CLAUDE.md? The wizard appends a new section without touching your content. Wrote a custom section after the kickstart section? `--reconfigure` preserves everything past the section being regenerated.
17. **Tested installer** — 97-assertion shell-test harness (`test/test-wizard.sh`) with 17 fixture projects covering every detected stack, every flag, `--dry-run`, `--reconfigure`, smart merge, and false-positive guards.

## FAQ

**Works with any language?** Yes. Language-agnostic. The installer auto-detects 14+ stacks (Node/TS + frameworks, Python + frameworks, Go, Rust, Deno, Bun, Elixir, Ruby, Java, Kotlin, .NET, PHP, Make-driven). For anything not detected, run `/init` after install to auto-configure from your codebase.

**Slows down Claude?** No. SessionStart hook only loads files that have real content (stubs are skipped). Stop hook is pure bash and runs in under 100ms. Sub-agents launch only when needed.

**Existing project?** Yes. Installer never overwrites user files — individual copies with `copy_safe`.

**Already have CLAUDE.md?** The installer preserves it. If your CLAUDE.md has no Project-Specific Configuration section, the wizard appends one at the end (and writes `CLAUDE.md.bak` first). If it has one, the wizard replaces only that section without touching other content. Want to re-run the wizard later? `bash setup.sh --reconfigure`.

**Windows?** Use WSL or Git Bash to run the installer.

**How do I update?** `bash <(curl ...) --update`. Preserves your config, refreshes template files. If the schema has advanced since your install, you'll get a warning pointing you at `--reconfigure`.

**What model does Claude run?** The main session defaults to `opusplan` — Opus in plan mode, Sonnet in execution. That's the documented cost/quality sweet spot. Sub-agents route by cost/benefit: `security-reviewer` on Opus (highest stakes), `code-reviewer` on Sonnet (balanced), `test-runner` / `researcher` / `accessibility-reviewer` on Haiku 4.5 (cheap, fast). Override the main model with `--model=sonnet` (or any of opus / haiku) at install time.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to add playbooks, starters, agents, and skills.

## License

MIT
