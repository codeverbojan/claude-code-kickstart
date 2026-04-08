# Contributing to Claude Code Kickstart

Contributions welcome. Here's how to add value.

## What to Contribute

**High value:**
- New task playbooks (`/deploy`, `/migrate`, `/review-pr`, etc.)
- New stack starter configs (`starters/django.md`, `starters/sveltekit.md`, etc.)
- New agents for specific workflows
- Bug fixes in the installer

**Medium value:**
- Improvements to existing playbooks, agents, or skills
- Better auto-detection logic in setup.sh
- Documentation improvements

## How to Contribute

### New Playbook

Create `.claude/commands/your-command.md`:

```yaml
---
name: your-command
description: One-line description of what it does
---

# Playbook Title

## 1. Step Name
- Actionable instruction
- Actionable instruction

## 2. Next Step
...

$ARGUMENTS
```

**Rules:**
- Steps should be concrete and verifiable
- Include a verification step (run tests, check output)
- Add anti-rationalization where agents commonly cut corners
- Test with Claude Code on a real project before submitting

### New Starter Config

Create `starters/your-stack.md`. The section heading uses a placeholder — the installer substitutes the real number at install time (CLAUDE.md renumbering is handled dynamically):

```markdown
## __SECNUM__. Project-Specific Configuration

### Stack
[Framework + language]

### Build & Dev Commands
- `command` — what it does

### Code Conventions
- [Real conventions, not generic advice]
- [Things Claude wouldn't know without being told]

### Architecture
[Directory structure with purpose of each key directory]
[Key patterns and entry points]
```

**Rules:**
- Only include conventions that are non-obvious or framework-specific
- Don't repeat things Claude already knows
- Include architecture with actual directory layout
- Add detection logic to `setup.sh` if the framework can be auto-detected

### New Agent

Create `.claude/agents/your-agent.md`:

```yaml
---
name: your-agent
description: Third-person description of what it does and when
tools: Read, Grep, Glob, Bash
model: sonnet
effort: medium
color: blue
---

Instructions...
```

**Rules:**
- Description should be third-person ("Audits code..." not "Use to audit...")
- Include what it does AND when to trigger it
- Only use Opus for tasks requiring deep reasoning (security audits, complex analysis)
- Don't duplicate existing agent capabilities

## Quality Checklist

Before submitting a PR:

- [ ] Tested with Claude Code on a real project
- [ ] No time-sensitive references (dates, specific versions)
- [ ] Consistent terminology with existing files
- [ ] Follows naming conventions (gerund-form for skills, imperative for commands)
- [ ] CHEATSHEET.md updated if adding a new command or agent
- [ ] README.md updated if adding a new feature
- [ ] installer (setup.sh) syntax verified: `bash -n setup.sh`

## PR Format

```
## What
[One sentence: what you added/changed]

## Why
[One sentence: what problem this solves]

## Testing
[How you tested it]
```
