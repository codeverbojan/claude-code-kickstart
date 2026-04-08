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

# --- Gate 1: did the last turn actually touch code? --------------------------
# Inspect the transcript tail for Edit/Write/NotebookEdit tool use in the
# most recent assistant turn. If no transcript or no tool use, this was a
# conversational/research reply — allow stop.
TOUCHED_CODE=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  # Last ~40 jsonl lines cover the most recent assistant turn comfortably.
  if tail -n 40 "$TRANSCRIPT" 2>/dev/null | grep -qE '"name":\s*"(Edit|Write|NotebookEdit|MultiEdit)"'; then
    TOUCHED_CODE=1
  fi
fi

[ "$TOUCHED_CODE" = "0" ] && exit 0

# --- Gate 2: was the edit to code, or just config/docs/memory? ---------------
# Pull file_path values from recent tool inputs; if every touched file is
# docs/config/memory, allow stop.
CODE_EDIT=0
if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  PATHS=$(tail -n 80 "$TRANSCRIPT" 2>/dev/null | python3 -c "
import sys, json, re
paths = []
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        obj = json.loads(line)
    except Exception:
        continue
    # Walk for tool_use blocks with file_path input
    def walk(x):
        if isinstance(x, dict):
            if x.get('type') == 'tool_use' and x.get('name') in ('Edit','Write','MultiEdit','NotebookEdit'):
                p = (x.get('input') or {}).get('file_path') or (x.get('input') or {}).get('notebook_path')
                if p: paths.append(p)
            for v in x.values(): walk(v)
        elif isinstance(x, list):
            for v in x: walk(v)
    walk(obj)
print('\n'.join(paths[-10:]))
" 2>/dev/null)

  if [ -n "$PATHS" ]; then
    while IFS= read -r p; do
      [ -z "$p" ] && continue
      case "$p" in
        *.md|*.mdx|*.txt|*.json|*.yaml|*.yml|*.toml|*.ini|*.cfg|*.env*|*.lock|*CLAUDE*|*primer*|*gotchas*|*patterns*|*decisions*|*.claude/*|*.github/*|*README*|*LICENSE*)
          ;;
        *)
          CODE_EDIT=1
          ;;
      esac
    done <<EOF
$PATHS
EOF
  else
    # Couldn't extract paths but tool use was detected → be conservative.
    CODE_EDIT=1
  fi
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
