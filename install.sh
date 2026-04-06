#!/bin/bash
set -e

# Claude Code Kickstart — One-Click Installer
# Copies the agentic workflow template into your current project.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh | bash
#
# Or clone and run:
#   git clone https://github.com/codeverbojan/claude-code-kickstart.git /tmp/cck && bash /tmp/cck/install.sh

REPO="https://github.com/codeverbojan/claude-code-kickstart.git"
TMP_DIR=$(mktemp -d)
TARGET_DIR="${1:-.}"

# Cleanup temp dir on exit (success or failure)
trap 'rm -rf "$TMP_DIR"' EXIT

echo "==> Claude Code Kickstart Installer"
echo ""

# Clone the template
echo "  Downloading template..."
git clone --quiet --depth 1 "$REPO" "$TMP_DIR" 2>/dev/null

# Copy a single file without overwriting
copy_safe() {
  local src="$1"
  local dst="$2"
  if [ -f "$dst" ]; then
    echo "  [SKIP] $dst already exists"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo "  [COPY] $dst"
}

cd "$TARGET_DIR"

echo ""
echo "  Installing into: $(pwd)"
echo ""

# Core files
copy_safe "$TMP_DIR/CLAUDE.md" "CLAUDE.md"
copy_safe "$TMP_DIR/primer.md" "primer.md"
copy_safe "$TMP_DIR/gotchas.md" "gotchas.md"
copy_safe "$TMP_DIR/CHEATSHEET.md" "CHEATSHEET.md"
copy_safe "$TMP_DIR/.claudeignore" ".claudeignore"
copy_safe "$TMP_DIR/.worktreeinclude" ".worktreeinclude"

# .claude config files
mkdir -p .claude
copy_safe "$TMP_DIR/.claude/settings.json" ".claude/settings.json"
copy_safe "$TMP_DIR/.claude/mcp.json" ".claude/mcp.json"

# Agents (individual files — won't skip existing agents you added)
mkdir -p .claude/agents
for agent in "$TMP_DIR"/.claude/agents/*.md; do
  [ -f "$agent" ] || continue
  copy_safe "$agent" ".claude/agents/$(basename "$agent")"
done

# Commands (individual files)
mkdir -p .claude/commands
for cmd in "$TMP_DIR"/.claude/commands/*.md; do
  [ -f "$cmd" ] || continue
  copy_safe "$cmd" ".claude/commands/$(basename "$cmd")"
done

# Skills (individual files within each skill directory)
for skill_dir in "$TMP_DIR"/.claude/skills/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  mkdir -p ".claude/skills/$skill_name"
  for skill_file in "$skill_dir"*; do
    [ -f "$skill_file" ] || continue
    copy_safe "$skill_file" ".claude/skills/$skill_name/$(basename "$skill_file")"
  done
done

echo ""
echo "==> Done! Claude Code Kickstart installed."
echo ""
echo "  Next steps:"
echo "    1. Customize CLAUDE.md with your project's rules (see Section 10)"
echo "    2. Edit .claude/settings.json to adjust permissions"
echo "    3. Run 'claude' to start a session"
echo "    4. Type /onboard to get oriented"
echo ""
echo "  Files installed:"
echo "    CLAUDE.md          — Operating rules for Claude (customize this!)"
echo "    primer.md          — Session state (auto-loaded)"
echo "    gotchas.md         — Mistake log (auto-loaded)"
echo "    CHEATSHEET.md      — Quick reference"
echo "    .claudeignore      — Files Claude should ignore"
echo "    .worktreeinclude   — Files to copy to worktrees"
echo "    .claude/           — Agents, commands, skills, settings"
echo ""
