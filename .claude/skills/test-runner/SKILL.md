---
name: test-runner
description: >
  Use when running tests, linting, or validation. Triggered before commits,
  after creating features, or when verifying code quality.
---

# Test Runner Skill

## When to Run Tests

- **Before every commit:** type-check + lint + unit tests
- **After new feature:** unit tests + integration tests
- **After refactor:** full suite to catch regressions
- **Before deployment:** full suite + E2E

## Run Order (priority)

1. Type-checker — catch type errors first
2. Linter — catch style/quality issues
3. Unit tests — fast, focused tests
4. Integration tests — cross-module tests
5. E2E tests — full browser/API tests (slowest)

## Interpreting Failures

### Type Errors
- Fix the type error. Don't use `any` or `@ts-ignore`.
- If a type is genuinely unknown, use `unknown` and narrow with type guards.

### Lint Errors
- Fix the code, don't disable the rule.
- If a rule is genuinely wrong for a case: add a disable comment with reason.

### Test Failures
- Read the assertion error. Fix the code, not the test (unless the test is wrong).
- If a test needs updating due to intentional changes, update expected values.

## You are FORBIDDEN from:
- Reporting "Done!" with failing tests
- Using `@ts-ignore` or `any` to bypass type errors
- Disabling lint rules without justification
- Skipping tests to make the suite pass
