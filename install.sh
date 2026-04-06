#!/bin/bash
set -e

# Claude Code Kickstart — Interactive Installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh | bash
#
# Skip wizard:
#   curl -fsSL ... | bash -s -- --skip-wizard
#
# Or clone and run:
#   git clone https://github.com/codeverbojan/claude-code-kickstart.git /tmp/cck && bash /tmp/cck/install.sh

REPO="https://github.com/codeverbojan/claude-code-kickstart.git"
TMP_DIR=$(mktemp -d)
TARGET_DIR="."
SKIP_WIZARD=false

# Parse args
for arg in "$@"; do
  case "$arg" in
    --skip-wizard) SKIP_WIZARD=true ;;
    *) TARGET_DIR="$arg" ;;
  esac
done

trap 'rm -rf "$TMP_DIR"' EXIT

# ─── Colors ───
BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RESET="\033[0m"

echo ""
echo -e "${BOLD}  Claude Code Kickstart${RESET}"
echo -e "${DIM}  Production-grade agentic workflow for Claude Code${RESET}"
echo ""

# ─── Download template ───
echo -e "  Downloading template..."
git clone --quiet --depth 1 "$REPO" "$TMP_DIR" 2>/dev/null
echo -e "  ${GREEN}Done.${RESET}"
echo ""

# ─── Copy helper ───
copy_safe() {
  local src="$1"
  local dst="$2"
  if [ -f "$dst" ]; then
    echo -e "  ${DIM}[SKIP]${RESET} $dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo -e "  ${GREEN}[COPY]${RESET} $dst"
}

cd "$TARGET_DIR"

# ─── Wizard ───

PROJECT_NAME=""
STACK=""
PKG_MGR=""
CMD_DEV=""
CMD_TYPECHECK=""
CMD_LINT=""
CMD_TEST=""
CMD_BUILD=""
CONVENTIONS=""

# Check if /dev/tty is available for interactive input (works even when piped)
HAS_TTY=false
if [ -e /dev/tty ]; then
  HAS_TTY=true
fi

if [ "$SKIP_WIZARD" = false ] && [ "$HAS_TTY" = true ]; then
  # Read from /dev/tty so the wizard works even when piped via curl | bash

  echo -e "${BOLD}  Setup Wizard${RESET}"
  echo -e "${DIM}  Answer a few questions to configure your project. Press Enter to skip any.${RESET}"
  echo ""

  # 1. Project name
  DEFAULT_NAME=$(basename "$(pwd)")
  printf "  Project name [$DEFAULT_NAME]: "
  read -r PROJECT_NAME </dev/tty
  PROJECT_NAME="${PROJECT_NAME:-$DEFAULT_NAME}"

  # 2. Stack
  echo ""
  echo -e "  ${BOLD}What's your stack?${RESET}"
  echo -e "  ${DIM}  1) Node.js / TypeScript (Next.js, Express, etc.)${RESET}"
  echo -e "  ${DIM}  2) Python (FastAPI, Django, Flask, etc.)${RESET}"
  echo -e "  ${DIM}  3) Go${RESET}"
  echo -e "  ${DIM}  4) Rust${RESET}"
  echo -e "  ${DIM}  5) Other / Mixed${RESET}"
  printf "  Choice [1]: "
  read -r STACK_CHOICE </dev/tty
  STACK_CHOICE="${STACK_CHOICE:-1}"

  case "$STACK_CHOICE" in
    1)
      STACK="node"
      echo ""
      echo -e "  ${BOLD}Package manager?${RESET}"
      echo -e "  ${DIM}  1) pnpm  2) npm  3) yarn  4) bun${RESET}"
      printf "  Choice [1]: "
      read -r PKG_CHOICE </dev/tty
      PKG_CHOICE="${PKG_CHOICE:-1}"
      case "$PKG_CHOICE" in
        1) PKG_MGR="pnpm" ;;
        2) PKG_MGR="npm" ;;
        3) PKG_MGR="yarn" ;;
        4) PKG_MGR="bun" ;;
        *) PKG_MGR="pnpm" ;;
      esac
      CMD_DEV="${PKG_MGR} dev"
      CMD_TYPECHECK="${PKG_MGR} typecheck"
      CMD_LINT="${PKG_MGR} lint"
      CMD_TEST="${PKG_MGR} test"
      CMD_BUILD="${PKG_MGR} build"
      ;;
    2)
      STACK="python"
      PKG_MGR="pip"
      CMD_DEV="python -m uvicorn main:app --reload"
      CMD_TYPECHECK="mypy ."
      CMD_LINT="ruff check ."
      CMD_TEST="pytest"
      CMD_BUILD=""
      ;;
    3)
      STACK="go"
      PKG_MGR="go"
      CMD_DEV="go run ."
      CMD_TYPECHECK="go vet ./..."
      CMD_LINT="golangci-lint run"
      CMD_TEST="go test ./..."
      CMD_BUILD="go build ."
      ;;
    4)
      STACK="rust"
      PKG_MGR="cargo"
      CMD_DEV="cargo run"
      CMD_TYPECHECK="cargo check"
      CMD_LINT="cargo clippy"
      CMD_TEST="cargo test"
      CMD_BUILD="cargo build --release"
      ;;
    *)
      STACK="other"
      PKG_MGR=""
      ;;
  esac

  # 3. Custom commands (let user override defaults)
  if [ "$STACK" != "other" ]; then
    echo ""
    echo -e "  ${BOLD}Commands${RESET} ${DIM}(press Enter to accept defaults)${RESET}"
    printf "  Dev server [$CMD_DEV]: "; read -r input </dev/tty; CMD_DEV="${input:-$CMD_DEV}"
    printf "  Type-check [$CMD_TYPECHECK]: "; read -r input </dev/tty; CMD_TYPECHECK="${input:-$CMD_TYPECHECK}"
    printf "  Lint [$CMD_LINT]: "; read -r input </dev/tty; CMD_LINT="${input:-$CMD_LINT}"
    printf "  Test [$CMD_TEST]: "; read -r input </dev/tty; CMD_TEST="${input:-$CMD_TEST}"
    if [ -n "$CMD_BUILD" ]; then
      printf "  Build [$CMD_BUILD]: "; read -r input </dev/tty; CMD_BUILD="${input:-$CMD_BUILD}"
    fi
  else
    echo ""
    echo -e "  ${BOLD}Commands${RESET} ${DIM}(enter your project commands, or leave blank)${RESET}"
    printf "  Dev server: "; read -r CMD_DEV </dev/tty
    printf "  Type-check: "; read -r CMD_TYPECHECK </dev/tty
    printf "  Lint: "; read -r CMD_LINT </dev/tty
    printf "  Test: "; read -r CMD_TEST </dev/tty
    printf "  Build: "; read -r CMD_BUILD </dev/tty
  fi

  # 4. Conventions
  echo ""
  printf "  Any code conventions to enforce? (e.g. 'strict TypeScript, no any'): "
  read -r CONVENTIONS </dev/tty

  echo ""
  echo -e "  ${GREEN}Got it.${RESET} Installing and configuring..."
  echo ""
fi

# ─── Install files ───

echo -e "  Installing into: ${BOLD}$(pwd)${RESET}"
echo ""

# Core files
copy_safe "$TMP_DIR/CLAUDE.md" "CLAUDE.md"
copy_safe "$TMP_DIR/primer.md" "primer.md"
copy_safe "$TMP_DIR/gotchas.md" "gotchas.md"
copy_safe "$TMP_DIR/CHEATSHEET.md" "CHEATSHEET.md"
copy_safe "$TMP_DIR/.claudeignore" ".claudeignore"
copy_safe "$TMP_DIR/.worktreeinclude" ".worktreeinclude"

# .claude config
mkdir -p .claude
copy_safe "$TMP_DIR/.claude/settings.json" ".claude/settings.json"
copy_safe "$TMP_DIR/.claude/mcp.json" ".claude/mcp.json"

# Agents
mkdir -p .claude/agents
for agent in "$TMP_DIR"/.claude/agents/*.md; do
  [ -f "$agent" ] || continue
  copy_safe "$agent" ".claude/agents/$(basename "$agent")"
done

# Commands
mkdir -p .claude/commands
for cmd in "$TMP_DIR"/.claude/commands/*.md; do
  [ -f "$cmd" ] || continue
  copy_safe "$cmd" ".claude/commands/$(basename "$cmd")"
done

# Skills
for skill_dir in "$TMP_DIR"/.claude/skills/*/; do
  [ -d "$skill_dir" ] || continue
  skill_name=$(basename "$skill_dir")
  mkdir -p ".claude/skills/$skill_name"
  for skill_file in "$skill_dir"*; do
    [ -f "$skill_file" ] || continue
    copy_safe "$skill_file" ".claude/skills/$skill_name/$(basename "$skill_file")"
  done
done

# ─── Configure from wizard answers ───

if [ -n "$CMD_DEV" ] || [ -n "$CONVENTIONS" ]; then
  # Build the project-specific section
  CONFIG_SECTION="## 10. Project-Specific Configuration"
  CONFIG_SECTION="$CONFIG_SECTION\n"

  # Stack
  if [ -n "$PROJECT_NAME" ]; then
    CONFIG_SECTION="$CONFIG_SECTION\n### Project\n$PROJECT_NAME\n"
  fi

  case "$STACK" in
    node)   CONFIG_SECTION="$CONFIG_SECTION\n### Stack\nNode.js / TypeScript\n" ;;
    python) CONFIG_SECTION="$CONFIG_SECTION\n### Stack\nPython\n" ;;
    go)     CONFIG_SECTION="$CONFIG_SECTION\n### Stack\nGo\n" ;;
    rust)   CONFIG_SECTION="$CONFIG_SECTION\n### Stack\nRust\n" ;;
  esac

  # Commands
  if [ -n "$CMD_DEV" ] || [ -n "$CMD_TEST" ]; then
    CONFIG_SECTION="$CONFIG_SECTION\n### Build & Dev Commands"
    [ -n "$CMD_DEV" ] && CONFIG_SECTION="$CONFIG_SECTION\n- \`$CMD_DEV\` — start dev server"
    [ -n "$CMD_BUILD" ] && CONFIG_SECTION="$CONFIG_SECTION\n- \`$CMD_BUILD\` — production build"
    [ -n "$CMD_TYPECHECK" ] && CONFIG_SECTION="$CONFIG_SECTION\n- \`$CMD_TYPECHECK\` — type check"
    [ -n "$CMD_LINT" ] && CONFIG_SECTION="$CONFIG_SECTION\n- \`$CMD_LINT\` — lint"
    [ -n "$CMD_TEST" ] && CONFIG_SECTION="$CONFIG_SECTION\n- \`$CMD_TEST\` — run tests"
    CONFIG_SECTION="$CONFIG_SECTION\n"
  fi

  # Conventions
  if [ -n "$CONVENTIONS" ]; then
    CONFIG_SECTION="$CONFIG_SECTION\n### Code Conventions\n$CONVENTIONS\n"
  fi

  CONFIG_SECTION="$CONFIG_SECTION\n### Architecture\n<!-- Describe directory structure, module boundaries, data flow -->"

  # Replace Section 10 in CLAUDE.md
  if [ -f "CLAUDE.md" ]; then
    # Find the line number where Section 10 starts and replace everything after it
    SECTION_LINE=$(grep -n "^## 10\. Project-Specific Configuration" CLAUDE.md | head -1 | cut -d: -f1)
    if [ -n "$SECTION_LINE" ]; then
      # Keep everything before Section 10, append new config
      head -n $((SECTION_LINE - 1)) CLAUDE.md > CLAUDE.md.tmp
      echo -e "$CONFIG_SECTION" >> CLAUDE.md.tmp
      mv CLAUDE.md.tmp CLAUDE.md
      echo -e "  ${GREEN}[CONFIGURED]${RESET} CLAUDE.md Section 10"
    fi
  fi

  # Update settings.json with stack-specific permissions
  if [ -f ".claude/settings.json" ] && [ "$STACK" = "rust" ]; then
    # Add cargo to permissions
    python3 -c "
import json
with open('.claude/settings.json') as f:
    s = json.load(f)
perms = s.get('permissions', {}).get('allow', [])
for cmd in ['Bash(cargo:*)', 'Bash(cargo *)','Bash(rustup:*)']:
    if cmd not in perms:
        perms.append(cmd)
s['permissions']['allow'] = perms
with open('.claude/settings.json', 'w') as f:
    json.dump(s, f, indent=2)
    f.write('\n')
" 2>/dev/null && echo -e "  ${GREEN}[CONFIGURED]${RESET} .claude/settings.json (added cargo permissions)"
  fi

  if [ -f ".claude/settings.json" ] && [ "$STACK" = "go" ]; then
    python3 -c "
import json
with open('.claude/settings.json') as f:
    s = json.load(f)
perms = s.get('permissions', {}).get('allow', [])
for cmd in ['Bash(go:*)', 'Bash(go *)']:
    if cmd not in perms:
        perms.append(cmd)
s['permissions']['allow'] = perms
with open('.claude/settings.json', 'w') as f:
    json.dump(s, f, indent=2)
    f.write('\n')
" 2>/dev/null && echo -e "  ${GREEN}[CONFIGURED]${RESET} .claude/settings.json (added go permissions)"
  fi

  if [ -f ".claude/settings.json" ] && [ "$STACK" = "python" ]; then
    python3 -c "
import json
with open('.claude/settings.json') as f:
    s = json.load(f)
perms = s.get('permissions', {}).get('allow', [])
for cmd in ['Bash(python:*)', 'Bash(python *)', 'Bash(pip:*)', 'Bash(pip *)', 'Bash(pytest:*)', 'Bash(pytest *)', 'Bash(ruff:*)', 'Bash(ruff *)', 'Bash(mypy:*)', 'Bash(mypy *)', 'Bash(uv:*)', 'Bash(uv *)']:
    if cmd not in perms:
        perms.append(cmd)
s['permissions']['allow'] = perms
# Symlink venv instead of node_modules
s['worktree'] = {'symlinkDirectories': ['.venv', '__pycache__']}
with open('.claude/settings.json', 'w') as f:
    json.dump(s, f, indent=2)
    f.write('\n')
" 2>/dev/null && echo -e "  ${GREEN}[CONFIGURED]${RESET} .claude/settings.json (added python permissions)"
  fi

  # Update primer.md with project-specific next steps
  if [ -f "primer.md" ] && [ -n "$PROJECT_NAME" ]; then
    python3 -c "
import sys
content = open('primer.md').read()
content = content.replace('Project initialized with Claude Code Kickstart template. No code written yet.',
    'Project \"$PROJECT_NAME\" initialized with Claude Code Kickstart template. No code written yet.')
open('primer.md', 'w').write(content)
" 2>/dev/null
  fi
fi

# ─── Summary ───

echo ""
echo -e "  ${GREEN}${BOLD}Done!${RESET} Claude Code Kickstart installed."
echo ""

if [ -n "$PROJECT_NAME" ]; then
  echo -e "  Project: ${BOLD}$PROJECT_NAME${RESET}"
fi
if [ -n "$STACK" ] && [ "$STACK" != "other" ]; then
  echo -e "  Stack:   ${BOLD}$STACK${RESET}"
fi
if [ -n "$PKG_MGR" ]; then
  echo -e "  Package: ${BOLD}$PKG_MGR${RESET}"
fi

echo ""
echo -e "  ${BOLD}What was installed:${RESET}"
echo "    CLAUDE.md          — Operating rules (customized for your stack)"
echo "    primer.md          — Session state (auto-loaded each session)"
echo "    gotchas.md         — Mistake log (auto-loaded, grows over time)"
echo "    CHEATSHEET.md      — Quick reference for commands + agents"
echo "    .claude/           — 5 agents, 9 commands, 2 skills, hooks"
echo ""
echo -e "  ${BOLD}Get started:${RESET}"
echo "    1. Run 'claude' to start a session"
echo "    2. Type /onboard to get oriented"
echo "    3. Use /fix, /feature, /refactor, /research for task playbooks"
echo "    4. Type /wrap-up when done to save session state"
echo ""
