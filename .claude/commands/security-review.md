---
name: security-review
description: Security review of recent changes — pre-flights git state with clear error guidance
---

# Security Review

Audits the diff between the working tree and the remote default branch
(`origin/HEAD`) for security issues. Wraps the built-in review with
preflight checks that fail loudly and explain how to fix common setup
problems — instead of bubbling up cryptic git errors.

## 1. Preflight — verify git state

Run these checks **in order**. If any fails, STOP and print the matching
"Fix" block to the user verbatim. Do not proceed until the user has fixed
the issue.

### Check A — is this a git repo?

```sh
git rev-parse --is-inside-work-tree
```

**If it fails:**

> **Not a git repository.** `/security-review` diffs against a remote
> branch, so it needs a git repo. Either `cd` into a repo, or run
> `git init && git remote add origin <url>` first.

### Check B — does the repo have a remote named `origin`?

```sh
git remote get-url origin
```

**If it fails:**

> **No `origin` remote.** `/security-review` diffs against `origin/HEAD`,
> which requires a remote. Add one with:
>
> ```sh
> git remote add origin <your-repo-url>
> git fetch origin
> git remote set-head origin --auto
> ```
>
> If this repo intentionally has no remote, run a full-tree audit instead
> by invoking the `security-reviewer` agent directly.

### Check C — is `refs/remotes/origin/HEAD` set?

```sh
git symbolic-ref refs/remotes/origin/HEAD
```

**If it fails with "is not a symbolic ref":**

> **`origin/HEAD` is not set on this repo.** This is the most common cause
> of `/security-review` failures and happens on repos that weren't freshly
> cloned. Fix it with one command:
>
> ```sh
> git remote set-head origin --auto
> ```
>
> This is a local-only, non-destructive bookkeeping change. It asks the
> remote which branch is default and points the local ref at it. Reverse
> with `git remote set-head origin --delete` if needed.
>
> **If `--auto` fails** (remote unreachable, or remote has no default
> branch), set it explicitly:
>
> ```sh
> git remote set-head origin main   # or master, develop, etc.
> ```

### Check D — does the diff have any content?

```sh
git diff --name-only origin/HEAD...
```

**If empty:**

> **No changes to review.** Your working tree matches `origin/HEAD`. If you
> want to audit the **whole repo** instead of a diff, invoke the
> `security-reviewer` agent directly and ask it to audit the full tree.

## 2. Run the review

Once preflight passes, list changed files with:

```sh
git diff --name-only origin/HEAD...
```

Then launch the `security-reviewer` agent on those files. Brief it with:
- The list of changed files
- Repo context (stack, framework — pull from CLAUDE.md Section 10)
- The specific concerns to look for (OWASP top 10, secrets, injection,
  authz, supply chain)

## 3. Report

Group findings by severity (Critical / High / Medium / Low / Info), with
file:line references and concrete remediation. End with a one-line verdict:
**SAFE TO MERGE** or **BLOCKERS PRESENT**.

$ARGUMENTS
