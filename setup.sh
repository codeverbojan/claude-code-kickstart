#!/bin/bash
set -e

# Claude Code Kickstart — Setup Script
# Called by install.sh after downloading the template.
# Can also be run directly: bash /tmp/cck/setup.sh /tmp/cck [target-dir] [--skip-wizard]

TMP_DIR="${1:-.}"
shift 2>/dev/null || true

TARGET_DIR="."
SKIP_WIZARD=false

for arg in "$@"; do
  case "$arg" in
    --skip-wizard) SKIP_WIZARD=true ;;
    *) TARGET_DIR="$arg" ;;
  esac
done

# ─── Colors ───
BOLD="\033[1m"
DIM="\033[2m"
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RESET="\033[0m"

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

if [ "$SKIP_WIZARD" = false ]; then

  echo -e "${BOLD}  Setup Wizard${RESET}"
  echo -e "${DIM}  Answer a few questions to configure your project. Press Enter to skip any.${RESET}"
  echo ""

  # 1. Project name
  DEFAULT_NAME=$(basename "$(pwd)")
  printf "  Project name [${BOLD}$DEFAULT_NAME${RESET}]: "
  read -r PROJECT_NAME
  PROJECT_NAME="${PROJECT_NAME:-$DEFAULT_NAME}"

  # 2. Stack
  echo ""
  echo -e "  ${BOLD}What's your stack?${RESET}"
  echo "    1) Node.js / TypeScript"
  echo "    2) Python"
  echo "    3) Go"
  echo "    4) Rust"
  echo "    5) Other / Mixed"
  printf "  Choice [${BOLD}1${RESET}]: "
  read -r STACK_CHOICE
  STACK_CHOICE="${STACK_CHOICE:-1}"

  case "$STACK_CHOICE" in
    1)
      STACK="node"
      echo ""
      echo -e "  ${BOLD}Package manager?${RESET}"
      echo "    1) pnpm  2) npm  3) yarn  4) bun"
      printf "  Choice [${BOLD}1${RESET}]: "
      read -r PKG_CHOICE
      PKG_CHOICE="${PKG_CHOICE:-1}"
      case "$PKG_CHOICE" in
        1) PKG_MGR="pnpm" ;;
        2) PKG_MGR="npm" ;;
        3) PKG_MGR="yarn" ;;
        4) PKG_MGR="bun" ;;
        *) PKG_MGR="pnpm" ;;
      esac
      if [ "$PKG_MGR" = "npm" ]; then
        CMD_DEV="npm run dev"
        CMD_TYPECHECK="npm run typecheck"
        CMD_LINT="npm run lint"
        CMD_TEST="npm test"
        CMD_BUILD="npm run build"
      else
        CMD_DEV="${PKG_MGR} dev"
        CMD_TYPECHECK="${PKG_MGR} typecheck"
        CMD_LINT="${PKG_MGR} lint"
        CMD_TEST="${PKG_MGR} test"
        CMD_BUILD="${PKG_MGR} build"
      fi
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

  # 3. Custom commands
  if [ "$STACK" != "other" ]; then
    echo ""
    echo -e "  ${BOLD}Commands${RESET} ${DIM}(press Enter to accept defaults)${RESET}"
    printf "  Dev server [$CMD_DEV]: "; read -r input; CMD_DEV="${input:-$CMD_DEV}"
    printf "  Type-check [$CMD_TYPECHECK]: "; read -r input; CMD_TYPECHECK="${input:-$CMD_TYPECHECK}"
    printf "  Lint [$CMD_LINT]: "; read -r input; CMD_LINT="${input:-$CMD_LINT}"
    printf "  Test [$CMD_TEST]: "; read -r input; CMD_TEST="${input:-$CMD_TEST}"
    if [ -n "$CMD_BUILD" ]; then
      printf "  Build [$CMD_BUILD]: "; read -r input; CMD_BUILD="${input:-$CMD_BUILD}"
    fi
  else
    echo ""
    echo -e "  ${BOLD}Commands${RESET} ${DIM}(enter your project commands, or leave blank)${RESET}"
    printf "  Dev server: "; read -r CMD_DEV
    printf "  Type-check: "; read -r CMD_TYPECHECK
    printf "  Lint: "; read -r CMD_LINT
    printf "  Test: "; read -r CMD_TEST
    printf "  Build: "; read -r CMD_BUILD
  fi

  # 4. Conventions
  echo ""
  printf "  Code conventions to enforce? (e.g. 'strict TypeScript, no any'): "
  read -r CONVENTIONS

  echo ""
  echo -e "  ${GREEN}Got it.${RESET} Installing..."
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
  CONFIG_SECTION="## 10. Project-Specific Configuration"
  CONFIG_SECTION="$CONFIG_SECTION\n"

  if [ -n "$PROJECT_NAME" ]; then
    CONFIG_SECTION="$CONFIG_SECTION\n### Project\n$PROJECT_NAME\n"
  fi

  case "$STACK" in
    node)   CONFIG_SECTION="$CONFIG_SECTION\n### Stack\nNode.js / TypeScript\n" ;;
    python) CONFIG_SECTION="$CONFIG_SECTION\n### Stack\nPython\n" ;;
    go)     CONFIG_SECTION="$CONFIG_SECTION\n### Stack\nGo\n" ;;
    rust)   CONFIG_SECTION="$CONFIG_SECTION\n### Stack\nRust\n" ;;
  esac

  if [ -n "$CMD_DEV" ] || [ -n "$CMD_TEST" ]; then
    CONFIG_SECTION="$CONFIG_SECTION\n### Build & Dev Commands"
    [ -n "$CMD_DEV" ] && CONFIG_SECTION="$CONFIG_SECTION\n- \`$CMD_DEV\` — start dev server"
    [ -n "$CMD_BUILD" ] && CONFIG_SECTION="$CONFIG_SECTION\n- \`$CMD_BUILD\` — production build"
    [ -n "$CMD_TYPECHECK" ] && CONFIG_SECTION="$CONFIG_SECTION\n- \`$CMD_TYPECHECK\` — type check"
    [ -n "$CMD_LINT" ] && CONFIG_SECTION="$CONFIG_SECTION\n- \`$CMD_LINT\` — lint"
    [ -n "$CMD_TEST" ] && CONFIG_SECTION="$CONFIG_SECTION\n- \`$CMD_TEST\` — run tests"
    CONFIG_SECTION="$CONFIG_SECTION\n"
  fi

  if [ -n "$CONVENTIONS" ]; then
    CONFIG_SECTION="$CONFIG_SECTION\n### Code Conventions\n$CONVENTIONS\n"
  fi

  CONFIG_SECTION="$CONFIG_SECTION\n### Architecture\n<!-- Describe directory structure, module boundaries, data flow -->"

  # Replace Section 10 in CLAUDE.md
  if [ -f "CLAUDE.md" ]; then
    SECTION_LINE=$(grep -n "^## 10\. Project-Specific Configuration" CLAUDE.md | head -1 | cut -d: -f1)
    if [ -n "$SECTION_LINE" ]; then
      head -n $((SECTION_LINE - 1)) CLAUDE.md > CLAUDE.md.tmp
      echo -e "$CONFIG_SECTION" >> CLAUDE.md.tmp
      mv CLAUDE.md.tmp CLAUDE.md
      echo -e "  ${GREEN}[CONFIGURED]${RESET} CLAUDE.md Section 10"
    fi
  fi

  # Stack-specific settings.json updates
  if [ -f ".claude/settings.json" ]; then
    if ! command -v python3 &>/dev/null; then
      echo -e "  ${YELLOW}[WARN]${RESET} python3 not found — skipping settings.json customization"
      echo -e "  ${DIM}  You can manually add stack-specific permissions to .claude/settings.json${RESET}"
    else
      case "$STACK" in
        rust)
          python3 -c "
import json
with open('.claude/settings.json') as f: s = json.load(f)
p = s.get('permissions', {}).get('allow', [])
for c in ['Bash(cargo:*)', 'Bash(cargo *)', 'Bash(rustup:*)']:
    if c not in p: p.append(c)
s['permissions']['allow'] = p
with open('.claude/settings.json', 'w') as f: json.dump(s, f, indent=2); f.write('\n')
" && echo -e "  ${GREEN}[CONFIGURED]${RESET} settings.json (cargo permissions)"
          ;;
        go)
          python3 -c "
import json
with open('.claude/settings.json') as f: s = json.load(f)
p = s.get('permissions', {}).get('allow', [])
for c in ['Bash(go:*)', 'Bash(go *)']:
    if c not in p: p.append(c)
s['permissions']['allow'] = p
with open('.claude/settings.json', 'w') as f: json.dump(s, f, indent=2); f.write('\n')
" && echo -e "  ${GREEN}[CONFIGURED]${RESET} settings.json (go permissions)"
          ;;
        python)
          python3 -c "
import json
with open('.claude/settings.json') as f: s = json.load(f)
p = s.get('permissions', {}).get('allow', [])
for c in ['Bash(python:*)', 'Bash(python *)', 'Bash(pip:*)', 'Bash(pip *)', 'Bash(pytest:*)', 'Bash(pytest *)', 'Bash(ruff:*)', 'Bash(ruff *)', 'Bash(mypy:*)', 'Bash(mypy *)', 'Bash(uv:*)', 'Bash(uv *)']:
    if c not in p: p.append(c)
s['permissions']['allow'] = p
s['worktree'] = {'symlinkDirectories': ['.venv', '__pycache__']}
with open('.claude/settings.json', 'w') as f: json.dump(s, f, indent=2); f.write('\n')
" && echo -e "  ${GREEN}[CONFIGURED]${RESET} settings.json (python permissions)"
          ;;
      esac
    fi
  fi

  # Update primer.md with project name (quote-safe via env var)
  if [ -f "primer.md" ] && [ -n "$PROJECT_NAME" ]; then
    if command -v python3 &>/dev/null; then
      PROJ_NAME="$PROJECT_NAME" python3 -c "
import os
name = os.environ['PROJ_NAME']
content = open('primer.md').read()
content = content.replace('Project initialized with Claude Code Kickstart template.',
    'Project \"' + name + '\" initialized with Claude Code Kickstart template.')
open('primer.md', 'w').write(content)
" 2>/dev/null
    else
      # Fallback: use sed for simple replacement (no special chars)
      sed -i.bak "s/Project initialized with Claude Code Kickstart template/Project \"${PROJECT_NAME}\" initialized with Claude Code Kickstart template/" primer.md 2>/dev/null
      rm -f primer.md.bak 2>/dev/null
    fi
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
echo -e "  ${BOLD}Get started:${RESET}"
echo "    1. Run 'claude' to start a session"
echo "    2. Type /onboard to get oriented"
echo "    3. Use /fix, /feature, /refactor, /research for task playbooks"
echo "    4. Type /wrap-up when done to save session state"
echo ""

# Cleanup temp dir (install.sh's trap doesn't fire after exec)
[ -d "$TMP_DIR" ] && [[ "$TMP_DIR" == /tmp/* || "$TMP_DIR" == /var/folders/* ]] && rm -rf "$TMP_DIR"
