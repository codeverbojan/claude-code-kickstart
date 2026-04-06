#!/usr/bin/env python3
"""Generate a scripted demo.cast file for Claude Code Kickstart."""

import json

events = []
t = 0.0

def out(text, delay=0.0):
    global t
    t += delay
    events.append([round(t, 3), "o", text])

def typed(text, delay=0.05):
    for ch in text:
        out(ch, delay)
    out("\r\n", 0.2)

def pause(s):
    global t
    t += s

def line(text, delay=0.02):
    out(text + "\r\n", delay)

# Colors
BOLD = "\x1b[1m"
DIM = "\x1b[2m"
GREEN = "\x1b[32m"
CYAN = "\x1b[36m"
YELLOW = "\x1b[33m"
BLUE = "\x1b[34m"
MAGENTA = "\x1b[35m"
RESET = "\x1b[0m"
GRAY = "\x1b[90m"

# Header
header = {"version": 2, "width": 92, "height": 32, "env": {"TERM": "xterm-256color"}}

# ─── Scene 1: Install ───
out(f"{GRAY}$ {RESET}", 0.5)
typed("bash <(curl -fsSL .../claude-code-kickstart/install.sh)")
pause(0.5)

line("")
line(f"  {BOLD}Claude Code Kickstart{RESET}")
line(f"  {DIM}Production-grade agentic workflow for Claude Code{RESET}")
line("")
line(f"  {GREEN}Auto-detected:{RESET}")
line(f"    Project:  {BOLD}my-nextjs-app{RESET}")
line(f"    Stack:    {BOLD}node{RESET}")
line(f"    Package:  {BOLD}pnpm{RESET}")
line(f"    Dev:      {DIM}pnpm dev{RESET}")
line(f"    Test:     {DIM}pnpm test{RESET}")
line(f"    Lint:     {DIM}pnpm lint{RESET}")
pause(0.8)
line("")
line(f"  Use {BOLD}Next.js{RESET} starter config? [Y/n]: Y")
pause(0.3)
line("")
line(f"  {GREEN}[COPY]{RESET} CLAUDE.md")
line(f"  {GREEN}[COPY]{RESET} primer.md, gotchas.md, patterns.md, decisions.md")
line(f"  {GREEN}[COPY]{RESET} .claude/ (5 agents, 11 commands, 2 skills)")
line(f"  {GREEN}[CONFIGURED]{RESET} CLAUDE.md Section 10 (Next.js starter)")
line(f"  {GREEN}[CREATED]{RESET} .npmrc (supply chain guards)")
line("")
line(f"  {GREEN}{BOLD}Done!{RESET} Installed in 3s.")
pause(2.0)

# ─── Scene 2: Start Claude ───
line("")
out(f"{GRAY}$ {RESET}", 0.3)
typed("claude")
pause(0.5)

line(f"  {DIM}Loading project context...{RESET}")
line(f"  {DIM}---PRIMER---{RESET}")
line(f"  Last session: Fresh install — Next.js + pnpm")
line(f"  Next steps: Start building")
line(f"  {DIM}---GOTCHAS--- No rules yet.{RESET}")
pause(1.0)

line("")
out(f"{CYAN}❯{RESET} ", 0.3)
typed("/onboard")
pause(0.3)

line("")
line(f"  {BOLD}Session Status{RESET}")
line(f"  State: Fresh install — Next.js + pnpm")
line(f"  Config: Section 10 configured (Next.js starter)")
line(f"  Gotchas: No rules yet")
line(f"  Decisions: None logged")
line(f"  {GREEN}Ready for first task.{RESET}")
pause(2.0)

# ─── Scene 3: Bug Fix ───
line("")
out(f"{CYAN}❯{RESET} ", 0.3)
typed("/fix login form crashes on empty email")
pause(0.5)

line("")
line(f"  {BOLD}1. Trace{RESET}")
line(f"  Root cause: {YELLOW}app/auth/login.ts:42{RESET}")
line(f"  Form submits without validation — no Zod schema on email field.")
line("")
line(f"  {BOLD}2. Fix{RESET}")
line(f"  Added: {GREEN}const schema = z.object({{ email: z.string().email() }}){RESET}")
line(f"  Added: {GREEN}schema.safeParse() before form.submit(){RESET}")
line("")
line(f"  {BOLD}3. Verify{RESET}")
line(f"  {GREEN}✓{RESET} pnpm typecheck — {GREEN}PASS{RESET}")
line(f"  {GREEN}✓{RESET} pnpm lint      — {GREEN}PASS{RESET}")
line(f"  {GREEN}✓{RESET} pnpm test      — {GREEN}PASS{RESET} (14 passed)")
line(f"  {GREEN}✓{RESET} Added regression test for empty email")
line("")
line(f"  {BOLD}4. Document{RESET}")
line(f"  Added gotcha: always validate form inputs with Zod before submit")
pause(3.0)

# ─── Scene 4: Wrap Up ───
line("")
out(f"{CYAN}❯{RESET} ", 0.3)
typed("/wrap-up")
pause(0.5)

line("")
line(f"  {BOLD}Session saved to primer.md{RESET}")
line("")
line(f"  {BOLD}What changed:{RESET}")
line(f"    app/auth/login.ts — added Zod email validation")
line(f"    app/auth/login.test.ts — added empty email test")
line("")
line(f"  Test status: {GREEN}PASS{RESET} (15 tests)")
line(f"  Decision logged: Zod for all form validation")
line(f"  Next command: {CYAN}/onboard fix signup form validation{RESET}")
pause(2.5)

# ─── Scene 5: Resume ───
line("")
line(f"  {DIM}# Next day...{RESET}")
pause(1.0)

out(f"{GRAY}$ {RESET}", 0.3)
typed("claude --continue")
pause(0.5)

line(f"  {DIM}Loading project context...{RESET}")
line("")
line(f"  {DIM}---SINCE LAST SESSION---{RESET}")
line(f"  Commits since 2026-04-06 18:30:")
line(f"  {YELLOW}a1b2c3d{RESET} fix: add Zod validation to login form")
line("")
line(f"  Last session: Fixed login crash — added Zod validation")
line(f"  Decisions: Zod for all form validation {DIM}(settled){RESET}")
line(f"  Gotchas: Always validate form inputs with Zod")
line(f"  Next step: {CYAN}Fix signup form validation{RESET}")
line("")
line(f"  {GREEN}Ready to continue.{RESET}")
pause(2.5)

# ─── Scene 6: Update ───
line("")
line(f"  {DIM}# A week later — new version released{RESET}")
pause(1.0)

out(f"{GRAY}$ {RESET}", 0.3)
typed("bash <(curl -fsSL .../install.sh) --update")
pause(0.5)

line("")
line(f"  {BOLD}Updating{RESET} — preserving CLAUDE.md, primer.md, gotchas.md,")
line(f"  patterns.md, decisions.md, settings.json")
line("")
line(f"  {GREEN}[UPDATE]{RESET} 5 agents, 11 commands, 2 skills")
line("")
line(f"  {GREEN}{BOLD}Done!{RESET} Your config untouched.")
pause(2.0)

# Write the .cast file
with open("demo.cast", "w") as f:
    f.write(json.dumps(header) + "\n")
    for event in events:
        f.write(json.dumps(event) + "\n")

print(f"Generated demo.cast ({len(events)} events, {round(t, 1)}s)")
print("Render with: agg demo.cast demo.gif --theme mocha --font-size 16")
