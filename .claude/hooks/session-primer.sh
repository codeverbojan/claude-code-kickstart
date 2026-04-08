#!/bin/bash
# SessionStart hook: load project context, skipping empty placeholder files.
#
# Claude Code already auto-loads CLAUDE.md on every session. This hook only
# contributes *dynamic* context (session state, recent commits) that CLAUDE.md
# cannot provide. Files matching template stubs are skipped to avoid burning
# tokens on a fresh install.

set -u

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
cd "$PROJECT_DIR" 2>/dev/null || exit 0

# Emit file contents only if the file is non-empty AND doesn't match a
# placeholder stub. Returns 0 if emitted, 1 if skipped.
emit_if_useful() {
  local label="$1"
  local file="$2"
  local stub_pattern="$3"

  [ -f "$file" ] || return 1
  [ -s "$file" ] || return 1

  # Skip if file is just the template stub.
  if grep -qE "$stub_pattern" "$file" 2>/dev/null; then
    # Check if the stub is ~all the file has (≤ 15 lines of mostly stub).
    local lines
    lines=$(wc -l < "$file" | tr -d ' ')
    if [ "$lines" -le 15 ]; then
      return 1
    fi
  fi

  printf '%s\n' "$label"
  cat "$file"
  printf '\n'
  return 0
}

# primer.md: always show if it exists and has content (no placeholder check —
# it's the one file that's meant to be session state).
if [ -f primer.md ] && [ -s primer.md ]; then
  cat primer.md
  printf '\n'
fi

emit_if_useful "---GOTCHAS---" gotchas.md "No gotchas yet"
emit_if_useful "---PATTERNS---" patterns.md "No patterns extracted yet"
emit_if_useful "---DECISIONS---" decisions.md "No decisions logged yet"

# Recent commits since primer.md was last touched.
if git rev-parse --git-dir >/dev/null 2>&1 && [ -f primer.md ]; then
  MTIME=$(stat -f%m primer.md 2>/dev/null || stat -c%Y primer.md 2>/dev/null)
  if [ -n "${MTIME:-}" ]; then
    SINCE=$(date -r "$MTIME" '+%Y-%m-%d %H:%M' 2>/dev/null || date -d "@$MTIME" '+%Y-%m-%d %H:%M' 2>/dev/null)
    ALL=$(git log --oneline --since="$MTIME" 2>/dev/null)
    if [ -n "$ALL" ]; then
      COUNT=$(printf '%s\n' "$ALL" | wc -l | tr -d ' ')
      SHOWN=$(printf '%s\n' "$ALL" | head -15)
      printf '\n---SINCE LAST SESSION---\n'
      printf 'Commits since %s:\n%s\n' "$SINCE" "$SHOWN"
      if [ "$COUNT" -gt 15 ]; then
        printf '... and %d more commits\n' "$((COUNT - 15))"
      fi
    fi
  fi
fi

exit 0
