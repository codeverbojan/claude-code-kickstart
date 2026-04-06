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

- Pin exact versions — no `^` or `~` in production deps
- Review `postinstall` scripts before adding any new dependency
- Reference: April 2026 Axios attack — maintainer account takeover injected
  phantom dependency with malicious postinstall hook
