---
name: lint
description: Run all linters across the project
---

Run linting checks:

1. Type-checker (e.g. `pnpm typecheck`, `tsc --noEmit`)
2. Linter (e.g. `pnpm lint`, `eslint .`, `ruff check .`)
3. Formatter check (e.g. `prettier --check .`, `ruff format --check .`)

Report any violations with file, line, and fix suggestion.

If a lint command doesn't exist or isn't configured, say so explicitly
instead of silently skipping it.
