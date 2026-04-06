---
name: init
description: Analyze the codebase and auto-generate CLAUDE.md Section 10 project config
---

# Auto-Configure Project

Analyze this codebase and generate a complete Section 10 for CLAUDE.md.
Do NOT ask the user questions — discover everything from the code.

## 1. Detect Stack

Check for these files and determine the stack:
- `package.json` → Node.js / TypeScript
- `go.mod` → Go
- `Cargo.toml` → Rust
- `pyproject.toml` / `requirements.txt` / `setup.py` → Python
- `Gemfile` → Ruby
- `pom.xml` / `build.gradle` → Java/Kotlin
- `composer.json` → PHP
- `*.csproj` / `*.sln` → C# / .NET
- `mix.exs` → Elixir
- `pubspec.yaml` → Flutter/Dart
- Multiple → list all

## 2. Detect Commands

**Node.js:** Read `package.json` `scripts` field. Map to actual commands.
**Python:** Check `Makefile`, `pyproject.toml` `[tool.pytest]`, `tox.ini`.
**Go:** Check `Makefile` targets. Default to `go test/vet/build`.
**Rust:** Default to `cargo check/clippy/test/build`.
**Any stack:** Check `Makefile`, `justfile`, `Taskfile.yml`, `docker-compose.yml`.

## 3. Detect Conventions

Read actual code to discover patterns (don't assume):
- **TypeScript:** Check `tsconfig.json` for strict mode. Check for `any` usage.
- **Linting:** Check `.eslintrc*`, `ruff.toml`, `.golangci.yml`, `clippy.toml`.
- **Formatting:** Check `.prettierrc*`, `biome.json`, `ruff.toml`, `rustfmt.toml`.
- **Testing:** Check test directory structure, framework config.
- **CSS:** Check for CSS modules, Tailwind, styled-components, etc.
- **Components:** Server vs client components, naming patterns.
- **Imports:** Barrel files, path aliases (`tsconfig.json` paths).

## 4. Detect Architecture

- Read the top-level directory structure
- Identify: monorepo (turbo.json, nx.json, lerna.json, pnpm-workspace.yaml)?
- Identify: app framework (Next.js app router, Django, Rails, FastAPI)?
- Map key directories to their purpose
- Note entry points (main files, route directories)

## 5. Write Section 10

Replace Section 10 in CLAUDE.md with what you discovered. Use this format:

```markdown
## 10. Project-Specific Configuration

### Stack
[What you found]

### Build & Dev Commands
- `command` — what it does
- `command` — what it does

### Code Conventions
- [Convention discovered from config files]
- [Convention discovered from code patterns]

### Architecture
[Directory structure with purpose of each key directory]
[Entry points]
[Key patterns: monorepo, app router, etc.]
```

Only write facts you verified from files. Don't guess or add generic advice.
If you can't detect anything for a sub-section, omit it entirely.
If the `## 10. Project-Specific Configuration` header doesn't exist in CLAUDE.md,
append it at the end of the file.

## 6. Report

Show the user what you wrote and ask if anything needs adjusting.

$ARGUMENTS
