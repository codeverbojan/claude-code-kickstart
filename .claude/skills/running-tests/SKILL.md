---
name: running-tests
description: >
  Provides test execution order, failure interpretation, and verification
  discipline. Triggered before commits, after code changes, or when
  verifying quality.
---

# Test Execution

## Run Order

Always run in this order — faster checks first catch errors cheaply:

```
1. Type-checker   (seconds — catches 80% of issues)
2. Linter         (seconds — catches style + security)
3. Unit tests     (seconds-minutes — catches logic)
4. Integration    (minutes — catches wiring)
5. E2E            (minutes — catches workflows, run last)
```

## Failure Rules

- Type error → fix the type. Never `any` or `@ts-ignore`.
- Lint error → fix the code. Disable only with written reason.
- Test failure → fix the code, not the test (unless the test is wrong).
- Show passing output in the same message. "I ran them earlier" is not evidence.
