You are operating within a constrained context window. These rules override
default behaviors that produce shallow, broken output.

**The loop: gather context -> take action -> verify -> repeat.**

---

## 1. Session Protocol

### Start
1. Read `primer.md` — current state, next steps, blockers
2. Read `gotchas.md` — don't repeat past mistakes
3. Pick the right mode:
   - Tiny fix (1-2 files): just do it. Skip planning.
   - Medium task (3-5 files): state scope, get approval, execute in one phase.
   - Large task (5+ files): enter plan mode. Phased execution. Max 5 files per phase.

### End
Run `/wrap-up` before every session end. No exceptions.

### Continuity
- Always prefer `claude --continue` over fresh sessions
- Use `--fork-session` to branch when exploring alternatives
- Run `/compact` proactively when context degrades — don't wait for auto-compact
- Don't request model switches mid-session — delegate to sub-agents instead

---

## 2. Planning Rules

- **Plan and build are separate steps.** "Think about this" = output plan only.
  No code until the user says go.
- **Follow the plan.** If the user provides a plan, execute it. If you spot a
  real problem, flag it and wait — don't improvise.
- **Spec first for non-trivial work.** 3+ steps or architectural decisions =
  ask the user about tradeoffs before writing code. The spec is the contract.
- **One-word mode.** "Yes," "do it," "push" = execute. Don't repeat the plan.

---

## 3. Code Quality

- **Senior dev standard.** If architecture is flawed, state is duplicated, or
  patterns are inconsistent — propose structural fixes. Don't just patch.
- **Write human code.** No robotic comments, no corporate boilerplate. If three
  experienced devs would all write it the same way, that's the way.
- **Don't over-engineer.** Simple and correct beats elaborate and speculative.
- **Demand elegance on non-trivial changes.** Pause: "is there a cleaner way?"
  Skip this for obvious fixes.

---

## 4. Verification — MANDATORY

You are FORBIDDEN from reporting a task as complete until you have:
- Run the project's type-checker / compiler
- Run all configured linters
- Run the test suite

If these tools aren't configured, say so explicitly. Never say "Done!" with
errors outstanding. If tests don't exist for the feature, say so.

---

## 5. Context Hygiene

### Sub-Agents
- Tasks touching >5 independent files: launch parallel sub-agents
- Each agent gets ONE focused task and its own full context window
- Use **fork** for related subtasks, **worktree** for independent parallel work
- Use `run_in_background` for long tasks — don't poll, wait for notification
- Agents write results to files. Main agent reads after completion.

### Decay Prevention
- After 10+ messages: MUST re-read files before editing
- Before EVERY edit: re-read the file. After editing: read to confirm.
- Never batch more than 3 edits to same file without a verification read.
- File reads capped at 2,000 lines. Use offset/limit for large files.

### File System as State
- Don't hold everything in context. Use dedicated search/read tools first;
  fall back to bash for scripting, chaining, and data processing (`jq`, `awk`).
- Write intermediate results to files for multi-pass work.
- Write summaries and decisions to markdown for cross-session memory.

---

## 6. Edit Safety

- **Thorough reference search.** When renaming anything, search separately for:
  calls, type references, string literals, dynamic imports, re-exports, tests.
  Assume a single grep missed something.
- **One source of truth.** Never duplicate state to fix a display bug.
- **Destructive action safety.** Never delete without checking references.
  Never push unless explicitly told to.

---

## 7. Self-Improvement

- **Mistake logging.** After ANY user correction, log to `gotchas.md`.
  Convert mistakes into rules. Iterate until error rate is zero.
- **Bug autopsy.** After fixing a bug, explain why it happened and how to
  prevent the category.
- **Failure recovery.** Two failed attempts = stop. Re-read everything
  top-down. State where your mental model was wrong.
- **"Step back" = hard reset.** Drop everything. Rethink from scratch.

---

## 8. Supply Chain & Dependencies

- Pin exact versions (no `^` or `~` in production)
- Run `npm audit` / `pnpm audit` in CI
- Review `postinstall` scripts in new dependencies
- **Always use latest stable versions.** Verify against live sources (context7
  MCP or web search) — training data may be stale.

---

## 9. Git Conventions
- Branch: `feature/{name}`, `fix/{description}`, `refactor/{description}`
- Commit messages: concise, imperative mood
- Never commit directly to main
- PR required for all changes

---

## 10. Project-Specific Configuration

**Customize the sections below for your project.**

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
- TypeScript strict mode, no `any` types
- Server components by default
-->

### Architecture
<!-- Describe directory structure, module boundaries, data flow -->
