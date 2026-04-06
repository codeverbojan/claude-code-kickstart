# Claude Code Kickstart — Demo
# Record: vhs demo.tape
# Install: brew install vhs

Output demo.gif

Set Shell "bash"
Set FontSize 14
Set Width 920
Set Height 540
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
Sleep 300ms

Hide
Type "./demo-output.sh install"
Enter
Sleep 100ms
Show

Sleep 3s

# ─── Scene 2: Start Claude ───

Type "claude"
Enter
Sleep 300ms

Hide
Type "./demo-output.sh session-start"
Enter
Sleep 100ms
Show

Sleep 1.5s

Type "/onboard"
Enter
Sleep 300ms

Hide
Type "./demo-output.sh onboard"
Enter
Sleep 100ms
Show

Sleep 2.5s

# ─── Scene 3: Fix a bug ───

Type "/fix login form crashes on empty email"
Enter
Sleep 300ms

Hide
Type "./demo-output.sh fix"
Enter
Sleep 100ms
Show

Sleep 4s

# ─── Scene 4: Wrap up ───

Type "/wrap-up"
Enter
Sleep 300ms

Hide
Type "./demo-output.sh wrapup"
Enter
Sleep 100ms
Show

Sleep 3s

# ─── Scene 5: Resume next day ───

Type "# Next day..."
Enter
Sleep 1s

Type "claude --continue"
Enter
Sleep 300ms

Hide
Type "./demo-output.sh resume"
Enter
Sleep 100ms
Show

Sleep 3s

# ─── Scene 6: Update ───

Type "# A week later — new version released"
Enter
Sleep 1s

Type "bash <(curl -fsSL .../install.sh) --update"
Enter
Sleep 300ms

Hide
Type "./demo-output.sh update"
Enter
Sleep 100ms
Show

Sleep 2.5s

Sleep 1s
