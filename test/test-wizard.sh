#!/bin/bash
# Wizard test harness for claude-code-kickstart setup.sh.
#
# For each fixture, copies the fixture to a temp dir, runs setup.sh
# --skip-wizard against it, and asserts expected behavior: CLAUDE.md
# Section 10 content, hooks directory, settings.json validity.
#
# Usage: bash test/test-wizard.sh
# Exit 0 = all pass. Exit 1 = at least one failure.

set -u

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
FIXTURES_DIR="$REPO_ROOT/test/fixtures"
SETUP="$REPO_ROOT/setup.sh"

PASS=0
FAIL=0
FAILED_TESTS=()

# ANSI colors (mirroring setup.sh style but self-contained)
if [ -t 1 ]; then
  G=$'\033[32m'; R=$'\033[31m'; Y=$'\033[33m'; DIM=$'\033[2m'; BOLD=$'\033[1m'; N=$'\033[0m'
else
  G=""; R=""; Y=""; DIM=""; BOLD=""; N=""
fi

fail() {
  FAIL=$((FAIL + 1))
  FAILED_TESTS+=("$1: $2")
  echo "  ${R}FAIL${N} $2"
}
pass() {
  PASS=$((PASS + 1))
  echo "  ${G}ok${N}   $1"
}

# Runs setup.sh --skip-wizard against a copy of $fixture and echoes the temp
# path it was installed into. Echoes to stderr on error.
run_setup() {
  local fixture="$1"
  local tmp
  tmp=$(mktemp -d)
  cp -R "$FIXTURES_DIR/$fixture"/* "$tmp"/ 2>/dev/null || true
  cp -R "$FIXTURES_DIR/$fixture"/.[!.]* "$tmp"/ 2>/dev/null || true
  # setup.sh signature: setup.sh <tmp-src-dir> [target-dir] [--flags]
  # When invoked standalone by tests, we point it at REPO_ROOT as the template
  # source and the fixture copy as the target.
  if bash "$SETUP" "$REPO_ROOT" "$tmp" --skip-wizard >"$tmp/.setup.log" 2>&1; then
    printf '%s' "$tmp"
  else
    printf '%s' "$tmp"
    echo "setup.sh exited non-zero; log at $tmp/.setup.log" >&2
    cat "$tmp/.setup.log" >&2
    return 1
  fi
}

# Assert a file exists in the install dir.
assert_file() {
  local name="$1" dir="$2" path="$3"
  if [ -f "$dir/$path" ]; then
    pass "$name: $path exists"
  else
    fail "$name" "$path missing"
  fi
}

# Assert a file contains a pattern (literal substring).
assert_contains() {
  local name="$1" dir="$2" path="$3" needle="$4"
  if [ ! -f "$dir/$path" ]; then
    fail "$name" "$path missing (expected to contain: $needle)"
    return
  fi
  if grep -qF "$needle" "$dir/$path"; then
    pass "$name: $path contains \"$needle\""
  else
    fail "$name" "$path missing expected content: $needle"
  fi
}

# Assert .claude/settings.json parses as JSON.
assert_settings_valid() {
  local name="$1" dir="$2"
  if [ ! -f "$dir/.claude/settings.json" ]; then
    fail "$name" ".claude/settings.json missing"
    return
  fi
  if python3 -c "import json; json.load(open('$dir/.claude/settings.json'))" 2>/dev/null; then
    pass "$name: settings.json is valid JSON"
  else
    fail "$name" ".claude/settings.json is not valid JSON"
  fi
}

# Assert every hook script exists and is executable.
assert_hooks_installed() {
  local name="$1" dir="$2"
  local missing=0
  for hook in verify-gate.sh session-primer.sh habits-coach.sh capture-signal.sh; do
    if [ ! -x "$dir/.claude/hooks/$hook" ]; then
      missing=1
      fail "$name" ".claude/hooks/$hook missing or not executable"
    fi
  done
  [ "$missing" = "0" ] && pass "$name: all hooks installed + executable"
}

# Cleanup temp dir unless KEEP_TMP=1 (for debugging).
cleanup() {
  local dir="$1"
  if [ "${KEEP_TMP:-0}" = "1" ]; then
    echo "  ${DIM}(kept temp dir: $dir)${N}"
  else
    rm -rf "$dir"
  fi
}

# --- Test cases ------------------------------------------------------------

echo "${BOLD}Running wizard tests${N}"
echo ""

# Assert that Section 10 replacement actually happened — the template has
# placeholder examples that MUST be gone after a successful install.
# This is the anti-false-positive guard: "<!-- Example:" appears in the
# template stubs but never in a populated Section.
assert_section_replaced() {
  local name="$1" dir="$2"
  if [ ! -f "$dir/CLAUDE.md" ]; then
    fail "$name" "CLAUDE.md missing"
    return
  fi
  # The template has "<!-- Example:" markers in the default Section.
  # A real install strips them. A broken install leaves them behind.
  if grep -q '<!-- Example:' "$dir/CLAUDE.md" 2>/dev/null; then
    fail "$name" "project-config section NOT replaced (<!-- Example: markers still present)"
  else
    pass "$name: project-config section was replaced"
  fi
}

# T1: Next.js fixture
echo "${BOLD}T1: Next.js detection${N}"
DIR=$(run_setup nextjs) || { echo "  setup failed"; cleanup "$DIR"; exit 1; }
assert_file "T1" "$DIR" "CLAUDE.md"
assert_file "T1" "$DIR" "primer.md"
assert_settings_valid "T1" "$DIR"
assert_hooks_installed "T1" "$DIR"
assert_section_replaced "T1" "$DIR"
assert_contains "T1" "$DIR" "CLAUDE.md" "pnpm"
cleanup "$DIR"
echo ""

# T2: Python FastAPI fixture
echo "${BOLD}T2: Python FastAPI detection${N}"
DIR=$(run_setup python-fastapi) || { echo "  setup failed"; cleanup "$DIR"; exit 1; }
assert_file "T2" "$DIR" "CLAUDE.md"
assert_settings_valid "T2" "$DIR"
assert_hooks_installed "T2" "$DIR"
assert_section_replaced "T2" "$DIR"
assert_contains "T2" "$DIR" "CLAUDE.md" "pytest"
cleanup "$DIR"
echo ""

# T3: Go with chi fixture
echo "${BOLD}T3: Go chi detection${N}"
DIR=$(run_setup go-chi) || { echo "  setup failed"; cleanup "$DIR"; exit 1; }
assert_file "T3" "$DIR" "CLAUDE.md"
assert_settings_valid "T3" "$DIR"
assert_hooks_installed "T3" "$DIR"
assert_section_replaced "T3" "$DIR"
assert_contains "T3" "$DIR" "CLAUDE.md" "go test"
cleanup "$DIR"
echo ""

# T4: Rust CLI fixture
echo "${BOLD}T4: Rust CLI detection${N}"
DIR=$(run_setup rust-cli) || { echo "  setup failed"; cleanup "$DIR"; exit 1; }
assert_file "T4" "$DIR" "CLAUDE.md"
assert_settings_valid "T4" "$DIR"
assert_hooks_installed "T4" "$DIR"
assert_section_replaced "T4" "$DIR"
assert_contains "T4" "$DIR" "CLAUDE.md" "cargo"
cleanup "$DIR"
echo ""

# T5: Empty directory (nothing to detect)
echo "${BOLD}T5: Empty directory${N}"
DIR=$(run_setup empty) || { echo "  setup failed"; cleanup "$DIR"; exit 1; }
assert_file "T5" "$DIR" "CLAUDE.md"
assert_settings_valid "T5" "$DIR"
assert_hooks_installed "T5" "$DIR"
cleanup "$DIR"
echo ""

# T-VS: version stamp added to generated Section
echo "${BOLD}T-VS: version stamp in generated Section${N}"
DIR=$(run_setup python-fastapi) || { echo "  setup failed"; cleanup "$DIR"; exit 1; }
assert_contains "T-VS" "$DIR" "CLAUDE.md" "cck:wizard-schema="
cleanup "$DIR"
echo ""

# T-RC: --reconfigure rerun against an already-populated Section regenerates it
echo "${BOLD}T-RC: --reconfigure regenerates existing Section${N}"
DIR=$(run_setup python-fastapi) || { echo "  setup failed"; cleanup "$DIR"; exit 1; }
# First install populated the section. Mark it so we can prove reconfigure rewrote it.
printf '\n<!-- CCK_TEST_MARKER -->\n' >> "$DIR/CLAUDE.md"
# Second pass in reconfigure mode.
if bash "$SETUP" "$REPO_ROOT" "$DIR" --reconfigure --skip-wizard >"$DIR/.recfg.log" 2>&1; then
  # After reconfigure, the marker below the Section header should be gone
  # (section was truncated + regenerated).
  if grep -q "CCK_TEST_MARKER" "$DIR/CLAUDE.md"; then
    fail "T-RC" "--reconfigure did not regenerate the section (marker still present)"
  else
    pass "T-RC: --reconfigure regenerated the section"
  fi
  # And the regenerated content should still have the version stamp.
  if grep -q "cck:wizard-schema=" "$DIR/CLAUDE.md"; then
    pass "T-RC: regenerated section has version stamp"
  else
    fail "T-RC" "regenerated section missing version stamp"
  fi
else
  fail "T-RC" "setup.sh --reconfigure exited non-zero"
  cat "$DIR/.recfg.log" >&2
fi
cleanup "$DIR"
echo ""

# T-UPD: --update against an un-stamped (old) CLAUDE.md warns about stale schema
echo "${BOLD}T-UPD: --update warns when wizard schema is stale${N}"
DIR=$(run_setup python-fastapi) || { echo "  setup failed"; cleanup "$DIR"; exit 1; }
# Strip the version stamp to simulate a v1 install.
sed -i.bak '/cck:wizard-schema=/d' "$DIR/CLAUDE.md" && rm -f "$DIR/CLAUDE.md.bak"
# Run update and capture output.
bash "$SETUP" "$REPO_ROOT" "$DIR" --update >"$DIR/.upd.log" 2>&1 || true
if grep -q "wizard schema" "$DIR/.upd.log"; then
  pass "T-UPD: --update warned about stale wizard schema"
else
  fail "T-UPD" "--update did not warn about stale schema (log below)"
  cat "$DIR/.upd.log" >&2
fi
cleanup "$DIR"
echo ""

# --- Stale §-reference regression guard ------------------------------------
# W1 ships fixes for these. The harness will fail on v1 setup.sh and pass
# on fixed setup.sh, giving us a regression anchor.
echo "${BOLD}T6: Response-style blocks reference correct § numbers${N}"
# Check the live setup.sh source directly (not an install output) — this
# is a static check that catches regressions if someone re-renumbers.
if grep -n 'CLAUDE\.md §4' "$SETUP" | grep -qi 'verification'; then
  fail "T6" "setup.sh still references CLAUDE.md §4 for verification (now §5)"
else
  pass "T6: no stale §4-verification references in setup.sh"
fi
if grep -n 'CLAUDE\.md §6' "$SETUP" | grep -qi 'over-engineer'; then
  fail "T6" "setup.sh references §6 for over-engineering (that's in §3)"
else
  pass "T6: no stale §6-over-engineering references in setup.sh"
fi
echo ""

# --- Summary ---------------------------------------------------------------
echo "${BOLD}Summary${N}"
echo "  ${G}passed: $PASS${N}"
if [ "$FAIL" -gt 0 ]; then
  echo "  ${R}failed: $FAIL${N}"
  echo ""
  echo "Failed assertions:"
  for line in "${FAILED_TESTS[@]}"; do
    echo "  - $line"
  done
  exit 1
fi
exit 0
