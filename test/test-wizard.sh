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

# Lightweight helper: run fixture, assert section replaced + expected stack line
quick_stack_test() {
  local label="$1" fixture="$2" expected="$3"
  echo "${BOLD}${label}: ${fixture} → ${expected}${N}"
  local DIR
  DIR=$(run_setup "$fixture") || { echo "  setup failed"; cleanup "$DIR"; return 1; }
  assert_settings_valid "$label" "$DIR"
  assert_section_replaced "$label" "$DIR"
  assert_contains "$label" "$DIR" "CLAUDE.md" "$expected"
  cleanup "$DIR"
  echo ""
}

# --- W3 stack expansion tests ---
quick_stack_test "T-DENO"    "deno"         "Deno"
quick_stack_test "T-ELIXIR"  "elixir"       "Elixir"
quick_stack_test "T-RUBY"    "ruby-rails"   "Ruby"
quick_stack_test "T-DOTNET"  "dotnet"       ".NET"
quick_stack_test "T-PHP"     "php-laravel"  "PHP"
quick_stack_test "T-MAKE"    "make-only"    "Make-driven"
quick_stack_test "T-DJANGO"  "django"       "Django"
quick_stack_test "T-FLASK"   "flask"        "Flask"
quick_stack_test "T-REMIX"   "remix"        "Remix"
quick_stack_test "T-TURBO"   "monorepo-turbo" "Turborepo monorepo"

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
# Run update. Capture exit code — a crash must not false-pass the test.
if bash "$SETUP" "$REPO_ROOT" "$DIR" --update >"$DIR/.upd.log" 2>&1; then
  UPD_EXIT=0
else
  UPD_EXIT=$?
fi
if [ "$UPD_EXIT" != "0" ]; then
  fail "T-UPD" "--update exited non-zero ($UPD_EXIT)"
  cat "$DIR/.upd.log" >&2
elif grep -q "wizard schema" "$DIR/.upd.log"; then
  pass "T-UPD: --update warned about stale wizard schema"
else
  fail "T-UPD" "--update did not warn about stale schema (log below)"
  cat "$DIR/.upd.log" >&2
fi
cleanup "$DIR"
echo ""

# T-RC-PRESERVE: --reconfigure preserves content after the target section.
# Regression test for the data-loss bug found in code review.
echo "${BOLD}T-RC-PRESERVE: --reconfigure keeps sections after project-config${N}"
DIR=$(run_setup python-fastapi) || { echo "  setup failed"; cleanup "$DIR"; exit 1; }
# Append a fake user-added section AFTER the project-config section.
cat >> "$DIR/CLAUDE.md" <<'TAIL'

## 99. User-added Testing Strategy

- Every PR must run the full suite before merge.
- Integration tests use real Postgres.
- UNIQUE_PHRASE_FOR_ASSERT_2026
TAIL
# Reconfigure and check the user section survived.
if bash "$SETUP" "$REPO_ROOT" "$DIR" --reconfigure --skip-wizard >"$DIR/.recfg.log" 2>&1; then
  if grep -q "UNIQUE_PHRASE_FOR_ASSERT_2026" "$DIR/CLAUDE.md"; then
    pass "T-RC-PRESERVE: user-added section survived --reconfigure"
  else
    fail "T-RC-PRESERVE" "--reconfigure DESTROYED the user-added section (data loss)"
  fi
  if grep -q "User-added Testing Strategy" "$DIR/CLAUDE.md"; then
    pass "T-RC-PRESERVE: user section heading preserved"
  else
    fail "T-RC-PRESERVE" "user section heading lost"
  fi
else
  fail "T-RC-PRESERVE" "--reconfigure exited non-zero"
  cat "$DIR/.recfg.log" >&2
fi
cleanup "$DIR"
echo ""

# T-W9-APPEND: existing CLAUDE.md without Project-Specific Configuration
# gets a new section appended (user content preserved, backup written)
echo "${BOLD}T-W9-APPEND: existing CLAUDE.md → append new section${N}"
DIR=$(run_setup existing-claude-md) || { echo "  setup failed"; cleanup "$DIR"; exit 1; }
# Original content must survive
if grep -q "UNIQUE_EXISTING_CONTENT_MARKER" "$DIR/CLAUDE.md"; then
  pass "T-W9-APPEND: original content preserved"
else
  fail "T-W9-APPEND" "original CLAUDE.md content destroyed"
fi
# New section must be appended
if grep -q "^## [0-9]\{1,2\}\. Project-Specific Configuration" "$DIR/CLAUDE.md"; then
  pass "T-W9-APPEND: new Project-Specific Configuration section added"
else
  fail "T-W9-APPEND" "new section not appended to existing CLAUDE.md"
fi
# Version stamp present
if grep -q "cck:wizard-schema=" "$DIR/CLAUDE.md"; then
  pass "T-W9-APPEND: version stamp present on appended section"
else
  fail "T-W9-APPEND" "version stamp missing after append"
fi
# Backup written
if [ -f "$DIR/CLAUDE.md.bak" ]; then
  pass "T-W9-APPEND: CLAUDE.md.bak written for safety"
else
  fail "T-W9-APPEND" "no backup created"
fi
cleanup "$DIR"
echo ""

# T-ADV-MODEL: --model=sonnet overrides the settings.json model
echo "${BOLD}T-ADV-MODEL: --model=sonnet overrides default${N}"
TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/python-fastapi"/* "$TMP"/
bash "$SETUP" "$REPO_ROOT" "$TMP" --skip-wizard --model=sonnet >"$TMP/.log" 2>&1 || true
if python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if d.get('model')=='sonnet' else 1)" "$TMP/.claude/settings.json" 2>/dev/null; then
  pass "T-ADV-MODEL: settings.json model = sonnet"
else
  fail "T-ADV-MODEL" "settings.json model was not sonnet after --model=sonnet"
fi
# Summary line must reflect the overridden model (not hardcoded "opusplan").
if grep -qE 'Main model:.*sonnet' "$TMP/.log" 2>/dev/null; then
  pass "T-ADV-MODEL: summary line reflects --model override"
else
  fail "T-ADV-MODEL" "summary line still shows opusplan after --model=sonnet"
fi
cleanup "$TMP"
echo ""

# T-ADV-MODEL-INVALID: --model=foobar must be rejected, not silently written
echo "${BOLD}T-ADV-MODEL-INVALID: reject unknown model${N}"
TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/python-fastapi"/* "$TMP"/
bash "$SETUP" "$REPO_ROOT" "$TMP" --skip-wizard --model=foobar >"$TMP/.log" 2>&1 || true
# settings.json must NOT have model=foobar. It should either be the default
# opusplan or absent entirely — what matters is "not the garbage input".
if python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(1 if d.get('model')=='foobar' else 0)" "$TMP/.claude/settings.json" 2>/dev/null; then
  pass "T-ADV-MODEL-INVALID: foobar model was rejected"
else
  fail "T-ADV-MODEL-INVALID" "settings.json was written with bogus model"
fi
# A WARN line should have been printed
if grep -q "unknown --model" "$TMP/.log"; then
  pass "T-ADV-MODEL-INVALID: warn message shown"
else
  fail "T-ADV-MODEL-INVALID" "no warn message for invalid model"
fi
cleanup "$TMP"
echo ""

# T-ADV-SKIP-AGENTS: --skip-agents omits specific agent files
echo "${BOLD}T-ADV-SKIP-AGENTS: --skip-agents=researcher,accessibility-reviewer${N}"
TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/python-fastapi"/* "$TMP"/
bash "$SETUP" "$REPO_ROOT" "$TMP" --skip-wizard --skip-agents=researcher,accessibility-reviewer >"$TMP/.log" 2>&1 || true
if [ ! -f "$TMP/.claude/agents/researcher.md" ]; then
  pass "T-ADV-SKIP-AGENTS: researcher.md skipped"
else
  fail "T-ADV-SKIP-AGENTS" "researcher.md was installed despite --skip-agents"
fi
if [ ! -f "$TMP/.claude/agents/accessibility-reviewer.md" ]; then
  pass "T-ADV-SKIP-AGENTS: accessibility-reviewer.md skipped"
else
  fail "T-ADV-SKIP-AGENTS" "accessibility-reviewer.md was installed despite --skip-agents"
fi
# Code-reviewer must NOT be skipped
if [ -f "$TMP/.claude/agents/code-reviewer.md" ]; then
  pass "T-ADV-SKIP-AGENTS: code-reviewer.md still installed"
else
  fail "T-ADV-SKIP-AGENTS" "code-reviewer.md was skipped (should be present)"
fi
cleanup "$TMP"
echo ""

# T-ADV-NO-MCP: --no-mcp skips .claude/mcp.json
echo "${BOLD}T-ADV-NO-MCP: --no-mcp skips MCP config${N}"
TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/python-fastapi"/* "$TMP"/
bash "$SETUP" "$REPO_ROOT" "$TMP" --skip-wizard --no-mcp >"$TMP/.log" 2>&1 || true
if [ ! -f "$TMP/.claude/mcp.json" ]; then
  pass "T-ADV-NO-MCP: mcp.json skipped"
else
  fail "T-ADV-NO-MCP" "mcp.json was installed despite --no-mcp"
fi
cleanup "$TMP"
echo ""

# T-ADV-NO-SECTION: --no-section skips CLAUDE.md Section replacement
echo "${BOLD}T-ADV-NO-SECTION: --no-section leaves CLAUDE.md stubs${N}"
TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/python-fastapi"/* "$TMP"/
bash "$SETUP" "$REPO_ROOT" "$TMP" --skip-wizard --no-section >"$TMP/.log" 2>&1 || true
# Section should remain unreplaced — stubs intact
if grep -q '<!-- Example:' "$TMP/CLAUDE.md" 2>/dev/null; then
  pass "T-ADV-NO-SECTION: template stubs preserved"
else
  fail "T-ADV-NO-SECTION" "--no-section did NOT preserve template stubs"
fi
# Python stack permissions must STILL have been applied — regression
# guard for the real-world bug where --no-section accidentally skipped
# the model override AND the stack-permissions block.
if python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if 'Bash(pytest:*)' in d.get('permissions',{}).get('allow',[]) else 1)" "$TMP/.claude/settings.json" 2>/dev/null; then
  pass "T-ADV-NO-SECTION: stack permissions still applied"
else
  fail "T-ADV-NO-SECTION" "stack permissions NOT applied — --no-section over-scoped"
fi
cleanup "$TMP"
echo ""

# T-ADV-NO-SECTION-MODEL: --no-section + --model must still write model to settings.json
echo "${BOLD}T-ADV-NO-SECTION-MODEL: --no-section + --model writes model${N}"
TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/python-fastapi"/* "$TMP"/
bash "$SETUP" "$REPO_ROOT" "$TMP" --skip-wizard --no-section --model=sonnet >"$TMP/.log" 2>&1 || true
if python3 -c "import json,sys; d=json.load(open(sys.argv[1])); sys.exit(0 if d.get('model')=='sonnet' else 1)" "$TMP/.claude/settings.json" 2>/dev/null; then
  pass "T-ADV-NO-SECTION-MODEL: --model=sonnet still applied with --no-section"
else
  fail "T-ADV-NO-SECTION-MODEL" "model override was silently dropped when combined with --no-section"
fi
cleanup "$TMP"
echo ""

# T-EXTRAS: substantive questions (DB/auth/deploy/LLM/secrets) populate Infrastructure
# Scripted via stdin — mimics a user answering: Y (look right), Y (starter),
# <blank> conventions, Y (extras), 1 (Postgres), 2 (Clerk), 1 (Vercel), y (LLM),
# 1 (.env), <blank> response style.
echo "${BOLD}T-EXTRAS: substantive questions populate Infrastructure block${N}"
TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/python-fastapi"/* "$TMP"/
# Interactive run, but from a fixture with detection → skips to confirm prompt.
# We need Y (look right?), <blank> or Y (starter?), <blank> (conventions),
# y (quick questions?), then the 5 extras answers, then <blank> (style).
printf 'Y\nY\n\ny\n1\n2\n1\ny\n1\n\n\n' | bash "$SETUP" "$REPO_ROOT" "$TMP" >"$TMP/.log" 2>&1 || true
if grep -q "### Infrastructure" "$TMP/CLAUDE.md" 2>/dev/null; then
  pass "T-EXTRAS: Infrastructure section present"
else
  fail "T-EXTRAS" "Infrastructure section missing"
  tail -30 "$TMP/.log" >&2
fi
# Match the exact Infrastructure-block format so the FastAPI starter's
# unrelated "Postgres" mention can't cause a false-positive.
if grep -q '\*\*Database:\*\* Postgres' "$TMP/CLAUDE.md" 2>/dev/null; then
  pass "T-EXTRAS: Postgres DB captured in Infrastructure"
else
  fail "T-EXTRAS" "Postgres Database line not in Infrastructure block"
fi
if grep -q '\*\*Auth:\*\* Clerk' "$TMP/CLAUDE.md" 2>/dev/null; then
  pass "T-EXTRAS: Clerk auth captured"
else
  fail "T-EXTRAS" "Clerk auth line not in Infrastructure block"
fi
if grep -q '\*\*Deployment:\*\* Vercel' "$TMP/CLAUDE.md" 2>/dev/null; then
  pass "T-EXTRAS: Vercel deploy captured"
else
  fail "T-EXTRAS" "Vercel deploy line not in Infrastructure block"
fi
if grep -q "LLM integration" "$TMP/CLAUDE.md" 2>/dev/null; then
  pass "T-EXTRAS: LLM-usage note captured"
else
  fail "T-EXTRAS" "LLM integration note missing"
fi
cleanup "$TMP"
echo ""

# T-EXTRAS-OFF: defaulting N to the "quick questions" toggle produces no Infrastructure
echo "${BOLD}T-EXTRAS-OFF: declining extras skips Infrastructure${N}"
TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/python-fastapi"/* "$TMP"/
# Y confirm, Y starter, <blank> conventions, <blank> (default N extras), <blank> style
printf 'Y\nY\n\n\n\n\n' | bash "$SETUP" "$REPO_ROOT" "$TMP" >"$TMP/.log" 2>&1 || true
if grep -q "### Infrastructure" "$TMP/CLAUDE.md" 2>/dev/null; then
  fail "T-EXTRAS-OFF" "Infrastructure section appeared when user declined extras"
else
  pass "T-EXTRAS-OFF: no Infrastructure section when extras declined"
fi
cleanup "$TMP"
echo ""

# T-CODEOWNERS: CODEOWNERS detection adds ownership section
echo "${BOLD}T-CODEOWNERS: CODEOWNERS → ownership note${N}"
DIR=$(run_setup with-codeowners) || { echo "  setup failed"; cleanup "$DIR"; exit 1; }
assert_section_replaced "T-CODEOWNERS" "$DIR"
assert_contains "T-CODEOWNERS" "$DIR" "CLAUDE.md" "### Ownership"
assert_contains "T-CODEOWNERS" "$DIR" "CLAUDE.md" "CODEOWNERS"
cleanup "$DIR"
echo ""

# T-TRY-EXAMPLE: post-install message shows a stack-aware concrete suggestion
echo "${BOLD}T-TRY-EXAMPLE: stack-aware 'Try:' in post-install${N}"
TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/python-fastapi"/* "$TMP"/
bash "$SETUP" "$REPO_ROOT" "$TMP" --skip-wizard >"$TMP/.log" 2>&1 || true
if grep -q 'Try:' "$TMP/.log" && grep -q 'health' "$TMP/.log"; then
  pass "T-TRY-EXAMPLE: FastAPI-specific /health example shown"
else
  fail "T-TRY-EXAMPLE" "expected 'Try: ... health' in install log"
  grep -A1 "Get started" "$TMP/.log" >&2 || true
fi
cleanup "$TMP"

TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/rust-cli"/* "$TMP"/
bash "$SETUP" "$REPO_ROOT" "$TMP" --skip-wizard >"$TMP/.log" 2>&1 || true
if grep -q 'Try:' "$TMP/.log" && grep -q 'clap' "$TMP/.log"; then
  pass "T-TRY-EXAMPLE: Rust-specific clap example shown"
else
  fail "T-TRY-EXAMPLE" "expected 'Try: ... clap' in install log"
fi
cleanup "$TMP"
echo ""

# T-EMPTY-SECTION: empty fixture must still get a populated section
# (no <!-- Example: stubs) — the reviewer caught this was previously silent.
echo "${BOLD}T-EMPTY-SECTION: empty fixture gets replaced section${N}"
DIR=$(run_setup empty) || { echo "  setup failed"; cleanup "$DIR"; exit 1; }
assert_section_replaced "T-EMPTY-SECTION" "$DIR"
assert_contains "T-EMPTY-SECTION" "$DIR" "CLAUDE.md" "cck:wizard-schema="
cleanup "$DIR"
echo ""

# T-STYLE: --style=concise flag injects the Concise response-style block
echo "${BOLD}T-STYLE: --style=concise flag${N}"
TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/python-fastapi"/* "$TMP"/
bash "$SETUP" "$REPO_ROOT" "$TMP" --skip-wizard --style=concise >"$TMP/.log" 2>&1 || true
if grep -q "Response Style: Concise" "$TMP/CLAUDE.md" 2>/dev/null; then
  pass "T-STYLE: concise style block was injected"
else
  fail "T-STYLE" "--style=concise did not inject Concise block"
fi
# Invalid style should NOT crash, should fall back.
cleanup "$TMP"
TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/python-fastapi"/* "$TMP"/
bash "$SETUP" "$REPO_ROOT" "$TMP" --skip-wizard --style=verbose >"$TMP/.log" 2>&1 || true
if grep -q "Response Style: Verbose" "$TMP/CLAUDE.md" 2>/dev/null; then
  fail "T-STYLE" "deprecated --style=verbose was honored; should fall back"
else
  pass "T-STYLE: deprecated verbose style correctly rejected / fell back"
fi
cleanup "$TMP"
echo ""

# T-DRYRUN: --dry-run writes nothing but reports detection
echo "${BOLD}T-DRYRUN: --dry-run writes no files${N}"
TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/python-fastapi"/* "$TMP"/
bash "$SETUP" "$REPO_ROOT" "$TMP" --dry-run >"$TMP/.log" 2>&1 || true
if [ -f "$TMP/CLAUDE.md" ] || [ -f "$TMP/primer.md" ] || [ -d "$TMP/.claude" ]; then
  fail "T-DRYRUN" "--dry-run created files (should have written nothing)"
else
  pass "T-DRYRUN: no files written"
fi
if grep -q "Dry run" "$TMP/.log"; then
  pass "T-DRYRUN: dry-run banner shown"
else
  fail "T-DRYRUN" "dry-run banner missing"
fi
if grep -q "Would write:" "$TMP/.log"; then
  pass "T-DRYRUN: 'would write' preview shown"
else
  fail "T-DRYRUN" "'would write' preview missing"
fi
cleanup "$TMP"
echo ""

# T-SUMMARY: final summary block lists stack / response style / model
echo "${BOLD}T-SUMMARY: Your setup summary block${N}"
TMP=$(mktemp -d)
cp -R "$FIXTURES_DIR/python-fastapi"/* "$TMP"/
bash "$SETUP" "$REPO_ROOT" "$TMP" --skip-wizard --style=concise >"$TMP/.log" 2>&1 || true
if grep -q "Your setup:" "$TMP/.log"; then
  pass "T-SUMMARY: Your setup block shown"
else
  fail "T-SUMMARY" "Your setup summary missing from output"
fi
if grep -q "Main model:" "$TMP/.log"; then
  pass "T-SUMMARY: main model line shown"
else
  fail "T-SUMMARY" "main model line missing"
fi
if grep -q "Response style:" "$TMP/.log"; then
  pass "T-SUMMARY: response style line shown"
else
  fail "T-SUMMARY" "response style line missing"
fi
cleanup "$TMP"
echo ""

# T-NOVERBOSE: setup.sh source must not retain a verbose response-style block
echo "${BOLD}T-NOVERBOSE: Verbose response style removed${N}"
if grep -q "Response Style: Verbose" "$SETUP"; then
  fail "T-NOVERBOSE" "setup.sh still contains a Verbose response-style block"
else
  pass "T-NOVERBOSE: no Verbose block in setup.sh"
fi
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
