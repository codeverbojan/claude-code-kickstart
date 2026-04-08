#!/bin/bash
# Stop hook: intelligent verification gate.
#
# Cheap command hook that only blocks when the last assistant turn actually
# modified functional code without showing verification output. Exits 0 to
# allow stop; exits 2 with stderr to block and nudge the model to verify.
#
# Replaces the old prompt-type Stop hook, which spawned an LLM judge on
# every turn — that doubled inference cost even for conversational replies.

set -u

INPUT=$(cat)

# Parse JSON via python3 (preferred) with grep fallback.
read_json() {
  local key="$1"
  printf '%s' "$INPUT" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    v = d.get('$key', '')
    print(v if isinstance(v, str) else '')
except Exception:
    pass
" 2>/dev/null
}

STOP_ACTIVE=$(printf '%s' "$INPUT" | python3 -c "
import sys, json
try: print('1' if json.load(sys.stdin).get('stop_hook_active') else '0')
except Exception: print('0')
" 2>/dev/null)

# Never recurse: if the hook is already active, let the stop proceed.
[ "$STOP_ACTIVE" = "1" ] && exit 0

LAST_MSG=$(read_json "last_assistant_message")
TRANSCRIPT=$(read_json "transcript_path")

# No message content to judge → allow stop.
[ -z "$LAST_MSG" ] && exit 0

# --- Gates 1 & 2: scope to CURRENT assistant turn only ---------------------
# Walk the transcript and collect Edit/Write/MultiEdit/NotebookEdit file_paths
# that appear AFTER the most recent user message. This avoids false positives
# from earlier turns lingering in a tail window.
CODE_EDIT=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  PATHS=$(python3 - "$TRANSCRIPT" <<'PY' 2>/dev/null
import sys, json

path = sys.argv[1]
entries = []
try:
    with open(path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            # Skip implausibly large transcript lines (>512 KB) — a Stop hook
            # that parses multi-MB jsonl on every turn would hang sessions.
            if len(line) > 524288:
                continue
            try:
                entries.append(json.loads(line))
            except Exception:
                pass
except Exception:
    sys.exit(0)

# Cap recursion in case the transcript has pathologically deep nesting.
sys.setrecursionlimit(2000)
MAX_DEPTH = 40
MAX_PATHS = 50

# Find the index of the most recent user message (role=user).
# Transcript entries vary in shape; check both top-level "role" and nested "message.role".
def get_role(entry):
    if isinstance(entry, dict):
        r = entry.get('role')
        if r: return r
        m = entry.get('message')
        if isinstance(m, dict):
            return m.get('role')
    return None

last_user_idx = -1
for i, e in enumerate(entries):
    if get_role(e) == 'user':
        last_user_idx = i

# Only inspect entries strictly after the last user message (current turn).
current_turn = entries[last_user_idx + 1:] if last_user_idx >= 0 else entries

EDIT_TOOLS = ('Edit', 'Write', 'MultiEdit', 'NotebookEdit')
paths = []

def walk(x, depth=0):
    if depth > MAX_DEPTH:
        return
    if len(paths) >= MAX_PATHS:
        return
    if isinstance(x, dict):
        if x.get('type') == 'tool_use' and x.get('name') in EDIT_TOOLS:
            inp = x.get('input') or {}
            p = inp.get('file_path') or inp.get('notebook_path')
            if p:
                paths.append(p)
                if len(paths) >= MAX_PATHS:
                    return
        for v in x.values():
            walk(v, depth + 1)
            if len(paths) >= MAX_PATHS:
                return
    elif isinstance(x, list):
        for v in x:
            walk(v, depth + 1)
            if len(paths) >= MAX_PATHS:
                return

for e in current_turn:
    walk(e)
    if len(paths) >= MAX_PATHS:
        break

print('\n'.join(paths))
PY
)

  # No edits in the current turn → allow stop (conversational / bash-only / etc).
  [ -z "$PATHS" ] && exit 0

  # Classify: treat docs/config/memory/tooling as non-functional.
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    case "$p" in
      *.md|*.mdx|*.txt|*.json|*.yaml|*.yml|*.toml|*.ini|*.cfg|*.env*|*.lock)
        ;;
      *CLAUDE*|*primer*|*gotchas*|*patterns*|*decisions*)
        ;;
      *.claude/*|*.github/*|*README*|*LICENSE*)
        ;;
      */setup.sh|*/install.sh|*/Makefile|*/makefile)
        ;;
      *)
        CODE_EDIT=1
        ;;
    esac
  done <<EOF
$PATHS
EOF
fi

[ "$CODE_EDIT" = "0" ] && exit 0

# --- Gate 3: did the assistant already show verification output? -------------
# Look for common test/lint/typecheck signals in the last message.
if printf '%s' "$LAST_MSG" | grep -qiE '(tests? pass|all pass|passing|0 errors|no errors|✓|✔|pass(ed)?|ok\b.*[0-9]+ pass|ran [0-9]+ test|lint.*clean|typecheck.*(ok|pass|clean))'; then
  exit 0
fi

# Also allow if the assistant explicitly acknowledged no test infra.
if printf '%s' "$LAST_MSG" | grep -qiE '(not configured|no tests? (yet|exist|configured)|no (lint|linter|typecheck) configured)'; then
  exit 0
fi

# --- Block: code changed, no verification shown ------------------------------
cat >&2 <<'MSG'
Verification gate: functional code was modified but no test/lint/typecheck
output is shown in this response. Run the project's verification commands
and show the output, or explicitly state that the relevant tooling is not
configured. See CLAUDE.md §4.
MSG
exit 2
