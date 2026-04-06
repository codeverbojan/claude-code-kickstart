---
name: securing-code
description: >
  Enforces secure coding patterns for API routes, auth, input handling, and
  database queries. Triggered when writing server-side code, handling user
  input, or adding dependencies.
---

# Secure Code Patterns

## API Route Handler Order

Always follow this sequence in every server-side handler:

```
1. Auth check
2. CSRF check (mutations only)
3. Input validation (schema-based)
4. Business logic (parameterized queries only)
5. Response
```

## Non-Obvious Rules

- CSRF tokens on ALL mutations (POST, PUT, DELETE) — not just forms
- Rate limit auth endpoints specifically (login, reset, signup)
- `sameSite=strict` on session cookies, not `lax`
- Set `X-Content-Type-Options: nosniff` — prevents MIME sniffing attacks
- Audit log sensitive operations (rate changes, user management, role changes)

## Supply Chain

Pin versions, block scripts, enforce soak periods. These are enforceable
guards, not advice — configure them in the project.

### Node.js (.npmrc)

```ini
# Block postinstall scripts by default (would have stopped the Axios attack)
ignore-scripts=true

# 7-day soak period — don't install packages published in the last week
minimum-release-age=10080

# Pin exact versions — no ^ or ~
save-exact=true

# Enforce peer deps and run audit on every install
strict-peer-dependencies=true
audit=true
```

After adding `ignore-scripts=true`, explicitly allow trusted scripts:
```bash
pnpm config set allow-scripts "esbuild,sharp,prisma"
```

### Python (pip)

```bash
# Pin with hashes for integrity verification
pip install --require-hashes -r requirements.txt

# Generate pinned requirements with hashes
pip-compile --generate-hashes requirements.in
```

### Go

```bash
# Verify module checksums against public transparency log
GONOSUMCHECK= GOFLAGS=-mod=readonly go build ./...
```

### Rust

```toml
# Cargo.toml — use exact versions
[dependencies]
serde = "=1.0.210"
```

```bash
# Audit for known vulnerabilities
cargo audit
```

### When adding ANY new dependency

1. Check: maintainer count, download volume, last publish date
2. Review: `postinstall` / build scripts in the package
3. Verify: no phantom transitive dependencies added
4. Wait: prefer packages with 7+ days since last publish
