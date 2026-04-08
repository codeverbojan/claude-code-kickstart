Be concise. State conclusions first. Skip preamble and filler.

Core loop: gather context → act → verify → repeat.

## 1. Session Protocol

**Start:** read `primer.md` (state, next steps) and `gotchas.md` (past mistakes).
Pick mode by scope:
- 1–2 files: just do it.
- 3–5 files: state scope, get approval, execute.
- 5+ files: plan mode, phased execution, max 5 files per phase.

**End:** run `/wrap-up` before closing the session.

**Continuity:** prefer `claude --continue` over fresh sessions. `--fork-session`
to branch. `/compact` proactively when context degrades. Don't switch models
mid-session — delegate to sub-agents.

## 2. Planning

- Plan and build are separate. "Think about this" = plan only, no code.
- If the user gives a plan, execute it. Flag real problems; don't improvise.
- Non-trivial work (3+ steps or architectural decisions): align on tradeoffs
  before writing code.
- One-word replies ("yes", "do it", "push") = execute, don't restate the plan.

## 3. Code Quality

- Senior-dev bar. Flawed architecture or duplicated state → propose structural
  fixes, don't just patch.
- Write human code. No robotic comments or boilerplate.
- Simple and correct beats elaborate and speculative.
- On non-trivial changes, pause once: "is there a cleaner way?"

## 4. Execution Loop

Non-negotiable workflow for any task beyond a trivial one-liner:

- **One task at a time.** Batch only closely-related small steps. Never
  implement task B before task A is fully done (impl + tests + review + fixes).
- **Implementation writes the tests.** Same context, same turn. Tests are not
  a follow-up task — they're part of the definition of done.
- **Checkpoint reviews in parallel.** After each meaningful chunk, launch
  review sub-agents concurrently (single message, multiple Agent calls).
  Minimum set: `code-reviewer`, `security-reviewer`, `test-runner`. Add
  `accessibility-reviewer` for UI work.
- **Review agents must read the plan first.** Every review agent gets the
  task description, intended behavior, and the list of files touched — not
  just "review my code". A reviewer without intent can't judge correctness.
- **Review scope:** bugs, security holes, data leaks, naming problems,
  inconsistencies, data corruption risks, edge cases, missing tests,
  race conditions.
- **Fix all valid findings before moving on.** No "I'll address this in a
  follow-up." If a finding is invalid, state why in one sentence.
- **Never defer quality, testing, or security to the end.** Each checkpoint
  is independently shippable.
- **Code understanding:** when tracing dependencies, following call graphs,
  or exploring unfamiliar code, prefer SocratiCode MCP tools (codebase_search,
  codebase_graph_query) over raw grep for non-trivial searches.

**Per-checkpoint report format** (always — don't skip fields):

```
Task: <what this chunk accomplishes>
Implementation: <files touched, approach in 1-2 lines>
Tests: <what was tested, pass/fail counts>
Review findings: <bullets from each reviewer, or "clean">
Fixes: <what changed in response to findings, or "none">
Status: <complete | blocked: reason>
```

Skip this format only for pure config/docs edits where reviewers have
nothing to judge — and say so explicitly ("pure docs edit, no review").

## 5. Verification

Before claiming a task complete, run the project's typecheck, lint, and tests,
and show the output in the same message. If tooling isn't configured, say so
explicitly. A command-type Stop hook enforces this for turns that edit code.

## 6. Context Hygiene

- 5+ independent files → parallel sub-agents, one focused task each. Use
  `fork` for related subtasks, `worktree` for independent parallel work.
- `run_in_background` for long tasks. Don't poll.
- File reads are capped at 2,000 lines; use offset/limit for large files.
- Re-read a file before editing if you haven't touched it recently or if
  many messages have passed since the last read.
- Prefer dedicated search/read tools over bash.

## 7. Edit Safety

- When renaming, search separately for calls, type refs, string literals,
  dynamic imports, re-exports, and tests.
- One source of truth. Don't duplicate state to fix a display bug.
- Never delete without checking references. Never push unless told to.

## 8. Self-Improvement

- After any user correction, log the lesson to `gotchas.md` as a rule.
- After fixing a bug, note the category so you can prevent it next time.
- Two failed attempts on the same problem = stop, re-read from the top,
  state where your mental model was wrong.
- "Step back" = full reset, rethink from scratch.

## 9. Supply Chain

- Pin exact versions in production (no `^`/`~`).
- `npm audit` / `pnpm audit` in CI.
- Review `postinstall` scripts on new dependencies.
- Verify library versions against live sources (context7 MCP, web search) —
  training data can be stale.

## 10. Git

- Branches: `feature/{name}`, `fix/{description}`, `refactor/{description}`.
- Concise, imperative commit messages.
- Never commit directly to main. PR required for all changes.

## 11. Project-Specific Configuration

Customize the sections below for your project.

### Stack
<!-- Example: Next.js 15 + React 19 + Postgres + Redis -->

### Build & Dev Commands
<!-- Example:
- `pnpm dev` — start dev server
- `pnpm typecheck` — TypeScript strict check
- `pnpm test` — run Vitest
-->

### Code Conventions
<!-- Example:
- TypeScript strict mode, no `any`
- Server components by default
-->

### Architecture
<!-- Directory structure, module boundaries, data flow -->
