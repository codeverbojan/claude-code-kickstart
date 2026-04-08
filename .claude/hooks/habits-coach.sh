#!/bin/bash
# User habits coach — nudges good practices via systemMessage.
# Called by UserPromptSubmit hook. Non-blocking, fast (pure bash).
#
# Shows max 1 tip per category per session. Tips are shown to the USER
# (via systemMessage), not to Claude.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
# Session-scoped tips file (hashed project path, macOS + Linux compatible)
HASH=$(printf '%s' "$PROJECT_DIR" | md5sum 2>/dev/null | cut -c1-8 || printf '%s' "$PROJECT_DIR" | md5 -q 2>/dev/null | cut -c1-8 || echo "default")
TIPS_SHOWN="/tmp/.claude-tips-${HASH}"

# Read prompt from stdin (safe JSON parsing via python3, fallback to grep)
INPUT=$(cat)
PROMPT=$(printf '%s' "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('prompt',''))" 2>/dev/null)
if [ -z "$PROMPT" ]; then
  PROMPT=$(printf '%s' "$INPUT" | grep -o '"prompt":"[^"]*"' | head -1 | sed 's/"prompt":"//;s/"$//')
fi

# Lowercase for matching
PROMPT_LOWER=$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')

[ -z "$PROMPT_LOWER" ] && exit 0

# Helper: show tip only once per session per category
show_tip() {
  local category="$1"
  local message="$2"

  # Check if already shown this session
  touch "$TIPS_SHOWN"
  if grep -q "^${category}$" "$TIPS_SHOWN" 2>/dev/null; then
    return
  fi

  # Mark as shown
  echo "$category" >> "$TIPS_SHOWN"

  # Return systemMessage (shown to user, not Claude)
  printf '{"systemMessage":"%s"}' "$message"
  exit 0
}

# --- Skip if user is already using a slash command ---
if printf '%s' "$PROMPT_LOWER" | grep -qE '^\s*/'; then

  # Special case: detect session ending without /wrap-up
  if printf '%s' "$PROMPT_LOWER" | grep -qE '^\s*/(clear|exit|quit)'; then
    # Check if session had significant work (signals file modified today)
    if [ -f "$PROJECT_DIR/.claude/signals.jsonl" ] || [ -f "$PROJECT_DIR/primer.md" ]; then
      show_tip "wrapup" "Tip: Run /wrap-up before ending to save session state for next time."
    fi
  fi

  exit 0
fi

# --- Check 1: Large scope (check FIRST — highest priority) ---
if printf '%s' "$PROMPT_LOWER" | grep -qE '(build (the )?entire|implement (all|everything)|set ?up (the )?(whole|full|complete)|from scratch)'; then
  show_tip "scope" "Tip: This sounds like a large task. Break it down with TaskCreate or use /feature for phased execution."
fi

# --- Check 2: Session ending without wrap-up ---
if printf '%s' "$PROMPT_LOWER" | grep -qE '^(bye|done|thanks|thank you|thats? (all|it)|im done|good ?bye|exit|quit|stop)'; then
  show_tip "wrapup" "Tip: Run /wrap-up before ending to save session state for next time."
fi

# --- Check 3: Vague task without playbook ---
if printf '%s' "$PROMPT_LOWER" | grep -qE '(fix (this|that|it|the bug)|its? (broken|not working|crashing)|doesnt? work|something.s wrong)'; then
  show_tip "playbook_fix" "Tip: Use /fix <description> for structured bug fixing — traces root cause before patching."
fi

if printf '%s' "$PROMPT_LOWER" | grep -qE '^(add|build|create|implement|make) (a |an |the |some )?[a-z]+ ?(feature|page|component|system|module|service|api|endpoint)'; then
  show_tip "playbook_feature" "Tip: Use /feature <description> for phased execution with verification."
fi

if printf '%s' "$PROMPT_LOWER" | grep -qE '(clean ?up|refactor|restructure|reorganize|simplify)'; then
  show_tip "playbook_refactor" "Tip: Use /refactor <description> — deletes dead code first, then restructures."
fi

# --- Check 4: First message guidance ---
# Fire on greetings or action words — anything that isn't a slash command
# and comes before any tips have been shown (first message of the session).
#
# Tip content depends on whether this is a fresh install. On fresh installs
# (primer.md still the template stub) /onboard has nothing to load, so we
# point the user at playbooks and task description instead.
IS_FRESH_INSTALL=0
# Match the fresh-install stub with either em-dash (U+2014) or plain hyphen,
# so a normalised primer.md (Windows editor, web paste) still trips the gate.
if [ -f "$PROJECT_DIR/primer.md" ] && grep -qE 'Fresh install (—|-) no previous sessions' "$PROJECT_DIR/primer.md" 2>/dev/null; then
  IS_FRESH_INSTALL=1
fi

if [ ! -f "$TIPS_SHOWN" ] || [ ! -s "$TIPS_SHOWN" ]; then
  # Greetings and short openers
  if printf '%s' "$PROMPT_LOWER" | grep -qE '^(hey|hi|hello|sup|yo|whats up|good morning|morning|hola|start)$'; then
    if [ "$IS_FRESH_INSTALL" = "1" ]; then
      show_tip "welcome" "Tip: Fresh install — just describe what you want to build. Use /fix, /feature, /refactor, or /research for structured playbooks."
    else
      show_tip "onboard" "Tip: Try /onboard to load project context, or /onboard <task> to jump into specific work."
    fi
  fi
  # Action words without a playbook
  if printf '%s' "$PROMPT_LOWER" | grep -qE '^(fix|build|add|create|implement|make|update|change|refactor|delete|remove)'; then
    if [ "$IS_FRESH_INSTALL" = "1" ]; then
      show_tip "welcome" "Tip: Fresh install — use /fix, /feature, /refactor, or /research for structured playbooks with built-in review."
    else
      show_tip "onboard" "Tip: Start with /onboard to load project context before jumping into work."
    fi
  fi
fi

# --- Check 5: No patterns.md after working ---
if [ -f "$PROJECT_DIR/patterns.md" ]; then
  if grep -q "No patterns extracted yet" "$PROJECT_DIR/patterns.md" 2>/dev/null; then
    # Only nudge after some work has happened (check if gotchas or signals exist)
    if [ -f "$PROJECT_DIR/.claude/signals.jsonl" ] || [ -f "$PROJECT_DIR/gotchas.md" ]; then
      if ! grep -q "No gotchas yet" "$PROJECT_DIR/gotchas.md" 2>/dev/null; then
        show_tip "learn" "Tip: Run /learn to extract code patterns from your codebase — makes every session smarter."
      fi
    fi
  fi
fi

exit 0
