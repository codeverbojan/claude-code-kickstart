# Claude Code Kickstart — Demo
# Record: vhs demo.tape
# Install vhs: brew install vhs

Output demo.gif

Set Shell "bash"
Set FontSize 13
Set Width 920
Set Height 520
Set Theme "Catppuccin Mocha"
Set Padding 16
Set TypingSpeed 30ms
Set CursorBlink false

# ─── Scene 1: Install ───

Type "cd ~/my-nextjs-app && bash <(curl -fsSL .../install.sh)"
Enter
Sleep 600ms

# Fake the installer output
Type@0ms "printf '\n  \033[1mClaude Code Kickstart\033[0m\n  \033[2mProduction-grade agentic workflow for Claude Code\033[0m\n\n  \033[32mAuto-detected:\033[0m\n    Project:  \033[1mmy-nextjs-app\033[0m\n    Stack:    \033[1mnode\033[0m\n    Package:  \033[1mpnpm\033[0m\n    Dev:      \033[2mpnpm dev\033[0m\n    Test:     \033[2mpnpm test\033[0m\n    Lint:     \033[2mpnpm lint\033[0m\n    Build:    \033[2mpnpm build\033[0m\n\n  Look right? [\033[1mY\033[0m/n]: '"
Enter
Sleep 1.5s

Type "Y"
Enter
Sleep 300ms

Type@0ms "printf '  Use \033[1mNext.js\033[0m starter config? [\033[1mY\033[0m/n]: '"
Enter
Sleep 800ms

Type "Y"
Enter
Sleep 300ms

Type@0ms "printf '  Code conventions? \033[2m(optional)\033[0m: '"
Enter
Sleep 600ms

Type "strict TypeScript, no any"
Enter
Sleep 300ms

Type@0ms "printf '\n  \033[32m[COPY]\033[0m CLAUDE.md\n  \033[32m[COPY]\033[0m primer.md\n  \033[32m[COPY]\033[0m gotchas.md\n  \033[32m[COPY]\033[0m .claude/ (5 agents, 10 commands, 2 skills)\n  \033[32m[CONFIGURED]\033[0m CLAUDE.md Section 10 (Next.js starter)\n  \033[32m[CREATED]\033[0m .npmrc (supply chain guards)\n\n  \033[32m\033[1mDone!\033[0m Installed in 3s.\n'"
Enter
Sleep 2.5s

# ─── Scene 2: First session ───

Type "claude"
Enter
Sleep 500ms
Type@0ms "printf '\033[2mLoading project context...\033[0m\n\n'"
Enter
Sleep 1s

Type@0ms "printf '\033[36m❯\033[0m '"
Enter
Sleep 400ms

Type "/onboard"
Enter
Sleep 500ms

Type@0ms "printf '\n  \033[1mSession Status\033[0m\n  State: Fresh install — Next.js + pnpm\n  Config: CLAUDE.md Section 10 configured (Next.js starter)\n  Gotchas: No rules yet\n  Next: Ready for first task\n\n'"
Enter
Sleep 2.5s

# ─── Scene 3: Bug fix ───

Type@0ms "printf '\033[36m❯\033[0m '"
Enter
Sleep 400ms

Type "/fix login form crashes on empty email"
Enter
Sleep 500ms

Type@0ms "printf '\n  \033[1m1. Trace\033[0m\n  Root cause: app/auth/login.ts:42 — form submits without validation\n  No Zod schema on the email field\n\n  \033[1m2. Fix\033[0m\n  Added: const schema = z.object({ email: z.string().email() })\n  Added: schema.safeParse() before form.submit()\n\n  \033[1m3. Verify\033[0m\n  ✓ pnpm typecheck — \033[32mPASS\033[0m\n  ✓ pnpm lint      — \033[32mPASS\033[0m\n  ✓ pnpm test      — \033[32mPASS\033[0m (14 passed)\n  ✓ Added regression test for empty email\n\n  \033[1m4. Document\033[0m\n  Added gotcha: always validate form inputs with Zod before submit\n\n'"
Enter
Sleep 4s

# ─── Scene 4: Wrap up ───

Type@0ms "printf '\033[36m❯\033[0m '"
Enter
Sleep 400ms

Type "/wrap-up"
Enter
Sleep 500ms

Type@0ms "printf '\n  \033[1mSession saved to primer.md\033[0m\n\n  What changed:\n    app/auth/login.ts — added Zod email validation\n    app/auth/login.test.ts — added empty email regression test\n\n  Test status: \033[32mPASS\033[0m (15 tests)\n  Uncommitted: 2 files staged\n  Next command: /onboard fix signup form validation\n\n'"
Enter
Sleep 3s

# ─── Scene 5: Resume next day ───

Type@0ms "printf '\033[2m# Next day...\033[0m\n'"
Enter
Sleep 1s

Type "claude --continue"
Enter
Sleep 500ms
Type@0ms "printf '\033[2mLoading project context...\033[0m\n\n'"
Enter
Sleep 800ms

Type@0ms "printf '  \033[1mLast session:\033[0m Fixed login crash — added Zod validation\n  \033[1mNext step:\033[0m Fix signup form validation\n  \033[1mGotchas:\033[0m Always validate form inputs with Zod before submit\n\n  Ready to continue.\n\n'"
Enter
Sleep 3s

# ─── Scene 6: Update ───

Type@0ms "printf '\033[2m# A week later — new version released\033[0m\n'"
Enter
Sleep 1s

Type "bash <(curl -fsSL .../install.sh) --update"
Enter
Sleep 500ms

Type@0ms "printf '\n  \033[1mUpdating\033[0m — preserving CLAUDE.md, primer.md, gotchas.md\n  \033[32m[UPDATE]\033[0m 5 agents, 10 commands, 2 skills\n  \033[32m\033[1mDone!\033[0m Your config untouched.\n\n'"
Enter
Sleep 2.5s

Sleep 1s
