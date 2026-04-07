#!/bin/bash
set -e

# Claude Code Kickstart — Setup Script
# Called by install.sh after downloading the template.
# Can also be run directly: bash /tmp/cck/setup.sh /tmp/cck [target-dir] [--skip-wizard]

TMP_DIR="${1:-.}"
shift 2>/dev/null || true

TARGET_DIR="."
SKIP_WIZARD=false
UPDATE_MODE=false

# CCK_SRC comes from install.sh (--src=X flag or env var). Also accept --src=X
# directly when setup.sh is invoked standalone.
CCK_SRC="${CCK_SRC:-direct}"

for arg in "$@"; do
  case "$arg" in
    --skip-wizard) SKIP_WIZARD=true ;;
    --update) UPDATE_MODE=true; SKIP_WIZARD=true ;;
    --src=*) CCK_SRC="${arg#--src=}" ;;
    --*) ;; # unknown flag — ignore instead of treating as target dir
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

# ─── Response-style wizard prompt ───
# Asks the user how verbose Claude should be. Fewer tokens = cheaper sessions
# but less explanation. More tokens = more context but higher cost per turn.
prompt_response_style() {
  echo ""
  echo -e "  ${BOLD}How should Claude respond?${RESET} ${DIM}(affects token cost per session)${RESET}"
  echo -e "    1) ${BOLD}Concise${RESET}  — short answers, minimal preamble. ${DIM}Least tokens.${RESET}"
  echo -e "    2) ${BOLD}Balanced${RESET} — short but complete explanations. ${DIM}Middle ground.${RESET}"
  echo -e "    3) ${BOLD}Verbose${RESET}  — detailed reasoning, trade-offs, examples. ${DIM}Most tokens.${RESET}"
  echo -e "    4) ${BOLD}Beginner${RESET} — plain language, no jargon. ${DIM}Explains like to a smart 15-year-old.${RESET}"
  printf "  Choice [${BOLD}2${RESET}]: "
  read -r STYLE_CHOICE
  case "${STYLE_CHOICE:-2}" in
    1) RESPONSE_STYLE="concise" ;;
    3) RESPONSE_STYLE="verbose" ;;
    4) RESPONSE_STYLE="beginner" ;;
    *) RESPONSE_STYLE="balanced" ;;
  esac
}

# ─── Build the response-style block injected into CLAUDE.md Section 10 ───
build_response_style_block() {
  case "$RESPONSE_STYLE" in
    concise)
      cat <<'STYLE_EOF'

### Response Style: Concise

- One-sentence answers where possible. Lead with the answer, never preamble.
- No trailing summaries of what you just did — the diff speaks for itself.
- No tables, no headers, no bullet lists unless the user explicitly asks for one.
- Code tasks: return the code with a one-line explanation only if non-obvious.
- Verification output still required per CLAUDE.md §4 (non-negotiable).
STYLE_EOF
      ;;
    verbose)
      cat <<'STYLE_EOF'

### Response Style: Verbose

- Explain your reasoning and trade-offs before the answer when decisions are non-trivial.
- Include concrete examples, alternatives considered, and why you ruled them out.
- Flag edge cases and assumptions the user should verify.
- Tables and structured formatting are welcome when they aid comprehension.
- Still obey CLAUDE.md §6 (no over-engineering) — verbose in *explanation*, not in code.
STYLE_EOF
      ;;
    beginner)
      cat <<'STYLE_EOF'

### Response Style: Beginner (plain language)

The user is not a professional developer. Explain everything as if you were
talking to a smart 15-year-old who is curious but doesn't know the jargon.

- **No jargon without defining it.** The first time you use a technical term
  (e.g. "dependency", "linter", "migration", "API", "env var"), explain what
  it means in one short sentence, then use it normally after.
- **Use analogies.** "Think of a dependency like a lego brick your project
  borrows from someone else." Analogies beat definitions for first-time learners.
- **Explain the *why* before the *how*.** Don't just say "run this command" —
  say what the command does and why it's the next step.
- **Warn before anything scary.** Before a command that deletes, overwrites,
  or pushes to the internet, say in plain words what it's about to do and ask
  for confirmation.
- **Celebrate small wins.** When something works, say so clearly: "Great — that
  worked. Now we can..." — momentum matters for non-technical users.
- **No sarcasm, no "obviously", no "just".** Those words make beginners feel dumb.
- **If the user asks a "stupid" question, treat it as a real one.** There are no
  stupid questions — only missing context.
- Still obey CLAUDE.md §4 verification — but explain the test output in plain words
  ("all 12 checks passed — your code looks healthy") instead of dumping raw logs.
STYLE_EOF
      ;;
    *)
      cat <<'STYLE_EOF'

### Response Style: Balanced

- Lead with the answer or action. Include only what's needed for the user to understand it.
- Short but complete: explain *why* for non-obvious decisions, skip the obvious.
- Use structure (bullets, short tables) only when it genuinely aids scanning.
- No trailing "here's what I did" summaries — only call out decisions or blockers.
STYLE_EOF
      ;;
  esac
}

# ─── Read a JSON key from package.json (no jq dependency) ───
pkg_script() {
  local key="$1"
  python3 -c "
import json, sys
try:
    d = json.load(open('package.json'))
    v = d.get('scripts', {}).get('$key', '')
    print(v)
except: pass
" 2>/dev/null
}

cd "$TARGET_DIR"

# ─── Auto-Detection ───

PROJECT_NAME=$(basename "$(pwd)")
STACK=""
PKG_MGR=""
CMD_DEV=""
CMD_TYPECHECK=""
CMD_LINT=""
CMD_TEST=""
CMD_BUILD=""
CONVENTIONS=""
RESPONSE_STYLE="balanced"  # concise | balanced | verbose
DETECTED=false

# Detect stack from project files
if [ -f "package.json" ]; then
  STACK="node"
  DETECTED=true

  # Detect package manager from lockfiles
  if [ -f "pnpm-lock.yaml" ]; then
    PKG_MGR="pnpm"
  elif [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
    PKG_MGR="bun"
  elif [ -f "yarn.lock" ]; then
    PKG_MGR="yarn"
  elif [ -f "package-lock.json" ]; then
    PKG_MGR="npm"
  else
    PKG_MGR="npm"
  fi

  # Read actual commands from package.json scripts
  if command -v python3 &>/dev/null; then
    _dev=$(pkg_script "dev")
    _typecheck=$(pkg_script "typecheck")
    _lint=$(pkg_script "lint")
    _test=$(pkg_script "test")
    _build=$(pkg_script "build")

    # If script exists in package.json, use the package manager runner
    if [ "$PKG_MGR" = "npm" ]; then
      [ -n "$_dev" ] && CMD_DEV="npm run dev"
      [ -n "$_typecheck" ] && CMD_TYPECHECK="npm run typecheck"
      [ -n "$_lint" ] && CMD_LINT="npm run lint"
      [ -n "$_test" ] && CMD_TEST="npm test"
      [ -n "$_build" ] && CMD_BUILD="npm run build"
    else
      [ -n "$_dev" ] && CMD_DEV="${PKG_MGR} dev"
      [ -n "$_typecheck" ] && CMD_TYPECHECK="${PKG_MGR} typecheck"
      [ -n "$_lint" ] && CMD_LINT="${PKG_MGR} lint"
      [ -n "$_test" ] && CMD_TEST="${PKG_MGR} test"
      [ -n "$_build" ] && CMD_BUILD="${PKG_MGR} build"
    fi
  fi

elif [ -f "go.mod" ]; then
  STACK="go"
  PKG_MGR="go"
  DETECTED=true
  CMD_DEV="go run ."
  CMD_TYPECHECK="go vet ./..."
  CMD_LINT="golangci-lint run"
  CMD_TEST="go test ./..."
  CMD_BUILD="go build ."

  # Check for Makefile targets
  if [ -f "Makefile" ]; then
    grep -q "^dev:" Makefile 2>/dev/null && CMD_DEV="make dev"
    grep -q "^test:" Makefile 2>/dev/null && CMD_TEST="make test"
    grep -q "^lint:" Makefile 2>/dev/null && CMD_LINT="make lint"
    grep -q "^build:" Makefile 2>/dev/null && CMD_BUILD="make build"
  fi

elif [ -f "Cargo.toml" ]; then
  STACK="rust"
  PKG_MGR="cargo"
  DETECTED=true
  CMD_DEV="cargo run"
  CMD_TYPECHECK="cargo check"
  CMD_LINT="cargo clippy"
  CMD_TEST="cargo test"
  CMD_BUILD="cargo build --release"

elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ] || [ -f "setup.py" ]; then
  STACK="python"
  DETECTED=true

  # Detect Python package manager
  if [ -f "uv.lock" ]; then
    PKG_MGR="uv"
  elif [ -f "poetry.lock" ]; then
    PKG_MGR="poetry"
  elif [ -f "Pipfile.lock" ]; then
    PKG_MGR="pipenv"
  else
    PKG_MGR="pip"
  fi

  CMD_TYPECHECK="mypy ."
  CMD_LINT="ruff check ."
  CMD_TEST="pytest"
  CMD_BUILD=""

  # Check for Makefile targets
  if [ -f "Makefile" ]; then
    grep -q "^dev:" Makefile 2>/dev/null && CMD_DEV="make dev"
    grep -q "^test:" Makefile 2>/dev/null && CMD_TEST="make test"
    grep -q "^lint:" Makefile 2>/dev/null && CMD_LINT="make lint"
  fi

  # Try to detect dev server from pyproject.toml
  if [ -z "$CMD_DEV" ] && [ -f "pyproject.toml" ]; then
    if grep -q "fastapi\|uvicorn" pyproject.toml 2>/dev/null; then
      CMD_DEV="uvicorn main:app --reload"
    elif grep -q "django" pyproject.toml 2>/dev/null; then
      CMD_DEV="python manage.py runserver"
    elif grep -q "flask" pyproject.toml 2>/dev/null; then
      CMD_DEV="flask run --reload"
    fi
  fi
fi

# ─── Show Detection Results / Run Wizard ───

if [ "$DETECTED" = true ] && [ "$SKIP_WIZARD" = false ]; then
  echo -e "  ${GREEN}Auto-detected:${RESET}"
  echo -e "    Project:  ${BOLD}$PROJECT_NAME${RESET}"
  echo -e "    Stack:    ${BOLD}$STACK${RESET}"
  echo -e "    Package:  ${BOLD}$PKG_MGR${RESET}"
  [ -n "$CMD_DEV" ] && echo -e "    Dev:      ${DIM}$CMD_DEV${RESET}"
  [ -n "$CMD_TYPECHECK" ] && echo -e "    Typecheck:${DIM} $CMD_TYPECHECK${RESET}"
  [ -n "$CMD_LINT" ] && echo -e "    Lint:     ${DIM}$CMD_LINT${RESET}"
  [ -n "$CMD_TEST" ] && echo -e "    Test:     ${DIM}$CMD_TEST${RESET}"
  [ -n "$CMD_BUILD" ] && echo -e "    Build:    ${DIM}$CMD_BUILD${RESET}"
  echo ""
  printf "  Look right? [${BOLD}Y${RESET}/n]: "
  read -r CONFIRM
  if [ "$CONFIRM" = "n" ] || [ "$CONFIRM" = "N" ]; then
    DETECTED=false
  else
    # Check for matching starter config
    STARTER_FILE=""
    USE_STARTER_CONFIG=""
    case "$STACK" in
      node)
        if [ -f "package.json" ] && grep -q '"next"' package.json 2>/dev/null; then
          STARTER_FILE="$TMP_DIR/starters/nextjs.md"
          STARTER_NAME="Next.js"
        fi
        ;;
      python)
        if [ -f "pyproject.toml" ] && grep -q "fastapi" pyproject.toml 2>/dev/null; then
          STARTER_FILE="$TMP_DIR/starters/fastapi.md"
          STARTER_NAME="FastAPI"
        fi
        ;;
      go)
        if [ -f "go.mod" ] && grep -q "chi\|gin\|echo\|fiber\|net/http" go.mod 2>/dev/null; then
          STARTER_FILE="$TMP_DIR/starters/go-api.md"
          STARTER_NAME="Go API"
        fi
        ;;
      rust)
        if [ -f "Cargo.toml" ] && grep -q "clap" Cargo.toml 2>/dev/null; then
          STARTER_FILE="$TMP_DIR/starters/rust-cli.md"
          STARTER_NAME="Rust CLI"
        fi
        ;;
    esac

    if [ -n "$STARTER_FILE" ] && [ -f "$STARTER_FILE" ]; then
      printf "  Use ${BOLD}$STARTER_NAME${RESET} starter config for Section 10? [${BOLD}Y${RESET}/n]: "
      read -r USE_STARTER
      if [ "$USE_STARTER" != "n" ] && [ "$USE_STARTER" != "N" ]; then
        USE_STARTER_CONFIG="$STARTER_FILE"
      fi
    fi

    # Ask for conventions (only thing we can't auto-detect)
    printf "  Code conventions to enforce? (optional): "
    read -r CONVENTIONS

    prompt_response_style
    echo ""
  fi
fi

if [ "$DETECTED" = false ] && [ "$SKIP_WIZARD" = false ]; then
  # Full manual wizard
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

  # 5. Response style
  prompt_response_style

  echo ""
  echo -e "  ${GREEN}Got it.${RESET} Installing..."
  echo ""
fi

# ─── Copy with overwrite (for update mode) ───
copy_force() {
  local src="$1"
  local dst="$2"
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  echo -e "  ${GREEN}[UPDATE]${RESET} $dst"
}

# ─── Install / Update files ───

if [ "$UPDATE_MODE" = true ]; then
  echo -e "  ${BOLD}Updating${RESET} in: ${BOLD}$(pwd)${RESET}"
  echo -e "${DIM}  Preserving: CLAUDE.md, primer.md, gotchas.md, patterns.md, decisions.md, settings.json, mcp.json${RESET}"
  echo ""

  # Update CHEATSHEET and ignore files (safe to overwrite)
  copy_force "$TMP_DIR/CHEATSHEET.md" "CHEATSHEET.md"
  copy_force "$TMP_DIR/.claudeignore" ".claudeignore"
  copy_force "$TMP_DIR/.worktreeinclude" ".worktreeinclude"

  # Update all agents (overwrite with latest)
  mkdir -p .claude/agents
  for agent in "$TMP_DIR"/.claude/agents/*.md; do
    [ -f "$agent" ] || continue
    copy_force "$agent" ".claude/agents/$(basename "$agent")"
  done

  # Update all commands (overwrite with latest)
  mkdir -p .claude/commands
  for cmd in "$TMP_DIR"/.claude/commands/*.md; do
    [ -f "$cmd" ] || continue
    copy_force "$cmd" ".claude/commands/$(basename "$cmd")"
  done

  # Update all skills (overwrite with latest)
  for skill_dir in "$TMP_DIR"/.claude/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    mkdir -p ".claude/skills/$skill_name"
    for skill_file in "$skill_dir"*; do
      [ -f "$skill_file" ] || continue
      copy_force "$skill_file" ".claude/skills/$skill_name/$(basename "$skill_file")"
    done
  done

else
  echo -e "  Installing into: ${BOLD}$(pwd)${RESET}"
  echo ""

  # Core files (never overwrite)
  copy_safe "$TMP_DIR/CLAUDE.md" "CLAUDE.md"
  copy_safe "$TMP_DIR/primer.md" "primer.md"
  copy_safe "$TMP_DIR/gotchas.md" "gotchas.md"
  copy_safe "$TMP_DIR/patterns.md" "patterns.md"
  copy_safe "$TMP_DIR/decisions.md" "decisions.md"
  copy_safe "$TMP_DIR/CHEATSHEET.md" "CHEATSHEET.md"
  copy_safe "$TMP_DIR/.claudeignore" ".claudeignore"
  copy_safe "$TMP_DIR/.worktreeinclude" ".worktreeinclude"

  # .claude config (never overwrite)
  mkdir -p .claude
  copy_safe "$TMP_DIR/.claude/settings.json" ".claude/settings.json"
  copy_safe "$TMP_DIR/.claude/mcp.json" ".claude/mcp.json"

  # Agents (individual, never overwrite)
  mkdir -p .claude/agents
  for agent in "$TMP_DIR"/.claude/agents/*.md; do
    [ -f "$agent" ] || continue
    copy_safe "$agent" ".claude/agents/$(basename "$agent")"
  done

  # Commands (individual, never overwrite)
  mkdir -p .claude/commands
  for cmd in "$TMP_DIR"/.claude/commands/*.md; do
    [ -f "$cmd" ] || continue
    copy_safe "$cmd" ".claude/commands/$(basename "$cmd")"
  done

  # Skills (individual, never overwrite)
  for skill_dir in "$TMP_DIR"/.claude/skills/*/; do
    [ -d "$skill_dir" ] || continue
    skill_name=$(basename "$skill_dir")
    mkdir -p ".claude/skills/$skill_name"
    for skill_file in "$skill_dir"*; do
      [ -f "$skill_file" ] || continue
      copy_safe "$skill_file" ".claude/skills/$skill_name/$(basename "$skill_file")"
    done
  done
fi

# ─── Configure from detection / wizard answers (skip in update mode) ───

if [ "$UPDATE_MODE" != true ] && { [ -n "$CMD_DEV" ] || [ -n "$CMD_TEST" ] || [ -n "$CONVENTIONS" ] || [ -n "${USE_STARTER_CONFIG:-}" ]; }; then

  # If a starter config was chosen, use it directly
  if [ -n "${USE_STARTER_CONFIG:-}" ] && [ -f "$USE_STARTER_CONFIG" ]; then
    CONFIG_SECTION=$(cat "$USE_STARTER_CONFIG")
    if [ -n "$CONVENTIONS" ]; then
      CONFIG_SECTION="$CONFIG_SECTION\n\n### Additional Conventions\n$CONVENTIONS"
    fi
  else
    # Build config from auto-detected/wizard values
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
  fi  # end of else (non-starter config)

  # Append response-style block (works for both starter and auto-gen paths —
  # real newlines are tolerated by both echo -e and printf '%s\n')
  STYLE_BLOCK=$(build_response_style_block)
  CONFIG_SECTION="${CONFIG_SECTION}
${STYLE_BLOCK}"

  # Replace Section 10 in CLAUDE.md — only if it still has the default placeholder
  if [ -f "CLAUDE.md" ]; then
    SECTION_LINE=$(grep -n "^## 10\. Project-Specific Configuration" CLAUDE.md | head -1 | cut -d: -f1)
    if [ -n "$SECTION_LINE" ]; then
      if grep -q "<!-- Example:" CLAUDE.md 2>/dev/null || grep -q "<!-- Describe directory" CLAUDE.md 2>/dev/null; then
        head -n $((SECTION_LINE - 1)) CLAUDE.md > CLAUDE.md.tmp
        if [ -n "${USE_STARTER_CONFIG:-}" ]; then
          # Starter content has real newlines from cat — use printf to avoid escape corruption
          printf '%s\n' "$CONFIG_SECTION" >> CLAUDE.md.tmp
        else
          # Auto-generated content uses \n literals — needs echo -e
          echo -e "$CONFIG_SECTION" >> CLAUDE.md.tmp
        fi
        mv CLAUDE.md.tmp CLAUDE.md
        echo -e "  ${GREEN}[CONFIGURED]${RESET} CLAUDE.md Section 10"
      else
        echo -e "  ${DIM}[SKIP]${RESET} CLAUDE.md Section 10 already customized"
      fi
    fi
  fi

  # Stack-specific settings.json updates
  if [ -f ".claude/settings.json" ]; then
    if ! command -v python3 &>/dev/null; then
      echo -e "  ${YELLOW}[WARN]${RESET} python3 not found — skipping settings.json customization"
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

  # Generate supply chain config
  case "$STACK" in
    node)
      if [ ! -f ".npmrc" ]; then
        cat > .npmrc << 'NPMRC'
# Supply chain security — generated by Claude Code Kickstart
ignore-scripts=true
minimum-release-age=10080
save-exact=true
strict-peer-dependencies=true
audit=true
NPMRC
        echo -e "  ${GREEN}[CREATED]${RESET} .npmrc (supply chain guards)"
      else
        echo -e "  ${DIM}[SKIP]${RESET} .npmrc already exists"
      fi
      ;;
    python)
      if [ ! -f "pyproject.toml" ] && [ ! -f "requirements.txt" ]; then
        cat > requirements.txt << 'REQS'
# Pin all dependencies with exact versions
# Generate with: pip-compile --generate-hashes requirements.in
REQS
        echo -e "  ${GREEN}[CREATED]${RESET} requirements.txt (placeholder)"
      fi
      ;;
    rust)
      if [ -f "Cargo.toml" ] && ! grep -q "cargo-audit" Cargo.toml 2>/dev/null; then
        echo -e "  ${DIM}[TIP]${RESET} Run 'cargo install cargo-audit && cargo audit' for vulnerability scanning"
      fi
      ;;
  esac

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
      sed -i.bak "s/Project initialized with Claude Code Kickstart template/Project \"${PROJECT_NAME}\" initialized with Claude Code Kickstart template/" primer.md 2>/dev/null
      rm -f primer.md.bak 2>/dev/null
    fi
  fi
fi

# ─── Record install source ───
# CCK_SRC is exported by install.sh (from --src=X flag or env var, defaults to "direct")
if [ -d ".claude" ]; then
  {
    echo "source: ${CCK_SRC:-direct}"
    echo "installed_at: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "mode: $([ "$UPDATE_MODE" = true ] && echo update || echo fresh)"
  } > .claude/install-source.txt
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
echo -e "  ${YELLOW}★${RESET} ${BOLD}If this saves you time, star the repo:${RESET}"
echo -e "    ${CYAN}https://github.com/codeverbojan/claude-code-kickstart${RESET}"
echo ""

# Cleanup temp dir (install.sh's trap doesn't fire after exec)
[ -d "$TMP_DIR" ] && [[ "$TMP_DIR" == /tmp/* || "$TMP_DIR" == /var/folders/* ]] && rm -rf "$TMP_DIR" || true
