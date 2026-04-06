# Claude Code Kickstart — Demo
# Record: vhs demo.tape
# Install: brew install vhs

Output demo.gif

Set Shell "bash"
Set FontSize 14
Set Width 900
Set Height 500
Set Theme "Catppuccin Mocha"
Set Padding 20
Set TypingSpeed 35ms
Set CursorBlink false

# ─── Scene 1: Install ───

Type "cd ~/my-nextjs-app"
Enter
Sleep 500ms

Type "bash <(curl -fsSL .../claude-code-kickstart/install.sh)"
Enter
Sleep 500ms

Hide
Type "cat << 'SCENE1'"
Enter
Type ""
Type "  Claude Code Kickstart"
Type "  Production-grade agentic workflow for Claude Code"
Type ""
Type "  Auto-detected:"
Type "    Project:  my-nextjs-app"
Type "    Stack:    node"
Type "    Package:  pnpm"
Type "    Dev:      pnpm dev"
Type "    Test:     pnpm test"
Type "    Lint:     pnpm lint"
Type "    Build:    pnpm build"
Type ""
Type "  Look right? [Y/n]: Y"
Type "  Use Next.js starter config? [Y/n]: Y"
Type "  Code conventions? (optional): strict TypeScript, no any"
Type ""
Type "  [COPY] CLAUDE.md"
Type "  [COPY] primer.md, gotchas.md, patterns.md, decisions.md"
Type "  [COPY] .claude/ (5 agents, 11 commands, 2 skills)"
Type "  [CONFIGURED] CLAUDE.md Section 10 (Next.js starter)"
Type "  [CREATED] .npmrc (supply chain guards)"
Type ""
Type "  Done! Installed in 3s."
Type ""
Type "SCENE1"
Enter
Show
Sleep 3s

# ─── Scene 2: First Session ───

Type "claude"
Enter
Sleep 300ms

Hide
Type "cat << 'SCENE2'"
Enter
Type "Loading project context..."
Type ""
Type "---PRIMER---"
Type "Last session: Fresh install — Next.js + pnpm"
Type "Next steps: Start building"
Type ""
Type "---GOTCHAS---"
Type "No rules yet."
Type ""
Type "---PATTERNS---"
Type "Run /learn to populate."
Type ""
Type "SCENE2"
Enter
Show
Sleep 2s

Hide
Type "cat << 'SCENE3'"
Enter
Type ""
Type "❯ "
Type "SCENE3"
Enter
Show
Sleep 300ms

Type "/onboard"
Enter
Sleep 300ms

Hide
Type "cat << 'SCENE4'"
Enter
Type ""
Type "  Session Status"
Type "  State: Fresh install — Next.js + pnpm"
Type "  Config: Section 10 configured (Next.js starter)"
Type "  Gotchas: No rules yet"
Type "  Decisions: None logged"
Type "  Ready for first task."
Type ""
Type "SCENE4"
Enter
Show
Sleep 2.5s

# ─── Scene 3: Bug Fix ───

Hide
Type "cat << 'SCENE5'"
Enter
Type "❯ "
Type "SCENE5"
Enter
Show
Sleep 300ms

Type "/fix login form crashes on empty email"
Enter
Sleep 300ms

Hide
Type "cat << 'SCENE6'"
Enter
Type ""
Type "  1. Trace"
Type "  Root cause: app/auth/login.ts:42 — form submits without validation"
Type "  No Zod schema on the email field."
Type ""
Type "  2. Fix"
Type "  Added: const schema = z.object({ email: z.string().email() })"
Type "  Added: schema.safeParse() before form.submit()"
Type ""
Type "  3. Verify"
Type "  ✓ pnpm typecheck — PASS"
Type "  ✓ pnpm lint      — PASS"
Type "  ✓ pnpm test      — PASS (14 passed)"
Type "  ✓ Added regression test for empty email"
Type ""
Type "  4. Document"
Type "  Added gotcha: always validate form inputs with Zod before submit"
Type ""
Type "SCENE6"
Enter
Show
Sleep 4s

# ─── Scene 4: Wrap Up ───

Hide
Type "cat << 'SCENE7'"
Enter
Type "❯ "
Type "SCENE7"
Enter
Show
Sleep 300ms

Type "/wrap-up"
Enter
Sleep 300ms

Hide
Type "cat << 'SCENE8'"
Enter
Type ""
Type "  Session saved to primer.md"
Type ""
Type "  What changed:"
Type "    app/auth/login.ts — added Zod email validation"
Type "    app/auth/login.test.ts — added empty email test"
Type ""
Type "  Test status: PASS (15 tests)"
Type "  Decision logged: Zod for all form validation"
Type "  Uncommitted: 2 files staged"
Type "  Next command: /onboard fix signup form validation"
Type ""
Type "SCENE8"
Enter
Show
Sleep 3s

# ─── Scene 5: Resume Next Day ───

Hide
Type "cat << 'SCENE9'"
Enter
Type ""
Type "# Next day..."
Type "SCENE9"
Enter
Show
Sleep 1s

Type "claude --continue"
Enter
Sleep 300ms

Hide
Type "cat << 'SCENE10'"
Enter
Type "Loading project context..."
Type ""
Type "---SINCE LAST SESSION---"
Type "Commits since 2026-04-06 18:30:"
Type "a1b2c3d fix: add Zod validation to login form"
Type ""
Type "  Last session: Fixed login crash — added Zod validation"
Type "  Decisions: Zod for all form validation (settled)"
Type "  Gotchas: Always validate form inputs with Zod before submit"
Type "  Next step: Fix signup form validation"
Type ""
Type "  Ready to continue."
Type ""
Type "SCENE10"
Enter
Show
Sleep 3s

# ─── Scene 6: Update ───

Hide
Type "cat << 'SCENE11'"
Enter
Type ""
Type "# A week later — new version released"
Type "SCENE11"
Enter
Show
Sleep 1s

Type "bash <(curl -fsSL .../install.sh) --update"
Enter
Sleep 300ms

Hide
Type "cat << 'SCENE12'"
Enter
Type ""
Type "  Updating — preserving CLAUDE.md, primer.md, gotchas.md,"
Type "  patterns.md, decisions.md, settings.json"
Type ""
Type "  [UPDATE] 5 agents, 11 commands, 2 skills"
Type ""
Type "  Done! Your config untouched."
Type ""
Type "SCENE12"
Enter
Show
Sleep 2.5s

Sleep 1s
