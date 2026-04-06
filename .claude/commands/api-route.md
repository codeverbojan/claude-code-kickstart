---
name: api-route
description: API route playbook — auth, validate, query, respond
---

# API Route Playbook

## 1. Design
- HTTP method + path
- Request schema (what fields, what types, what's required)
- Response schema (success + error shapes)
- Auth requirement (public, authenticated, admin-only)

## 2. Build
Follow this order in the handler:
1. **Auth check** — verify session/token, check role
2. **CSRF check** — on mutations (POST, PUT, DELETE)
3. **Input validation** — parse with schema (Zod, joi, Pydantic, etc.)
4. **Business logic** — parameterized queries only, never interpolate input
5. **Response** — proper status codes, consistent error shape

## 3. Security Checklist
- [ ] Auth on the endpoint
- [ ] Input validated server-side
- [ ] No secrets in response
- [ ] Parameterized DB queries
- [ ] Rate limiting considered
- [ ] Error messages don't leak internals

## 4. Verify
- Run type-checker
- Run linter
- Write/run tests for: happy path, validation error, auth failure, not found
- Consider using the `security-reviewer` agent for a deep audit.

$ARGUMENTS
