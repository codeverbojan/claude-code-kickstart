# Security Policy

## Supported Versions

This is a template repository. Only the `main` branch receives security
updates — fork or copy from `main` for the latest fixes.

## Reporting a Vulnerability

**Do not open a public issue for security vulnerabilities.**

If you discover a security issue in this template — for example, an unsafe
hook, a command injection in a shell script, a permissioning mistake, or
a supply-chain concern in the install flow — please report it privately:

1. Use GitHub's **"Report a vulnerability"** button under the repo's
   **Security** tab (preferred — creates a private advisory).
2. Or open a minimal public issue that says "security — please contact me"
   without details, and wait for a maintainer to reach out.

Please include:
- A clear description of the issue and its impact
- Steps to reproduce (or a proof of concept)
- The affected file(s) and commit SHA
- Your suggested fix, if you have one

## Scope

In scope:
- Shell scripts (`install.sh`, `setup.sh`, hooks under `.claude/`)
- Slash commands and agents that execute code
- `settings.json` hook configurations
- Any file that runs on a user's machine during install or session

Out of scope:
- Vulnerabilities in Claude Code itself (report to Anthropic)
- Issues in third-party tools the template references but does not ship

## Response

Maintainers will acknowledge reports within a reasonable time and work on
a fix before public disclosure. Please give us a chance to patch before
going public.
