#!/bin/bash
# Capture mistake signals to .claude/signals.jsonl
# Called by PostToolUse(Bash) hook — runs async, does not block Claude.
#
# Detects: git reverts (not unstaging), test/lint/typecheck failures (by exit code).
# All processing in Python for safe JSON encoding and secret scrubbing.

python3 -c "
import json, sys, os, re
from datetime import datetime, timezone

try:
    data = json.load(sys.stdin)
except (json.JSONDecodeError, TypeError):
    sys.exit(0)

command = data.get('tool_input', {}).get('command', '')
response = data.get('tool_response', {})
if isinstance(response, dict):
    response_text = json.dumps(response)
    # Try to extract exit code from structured response
    exit_code = response.get('exit_code', response.get('exitCode', 0))
else:
    response_text = str(response)
    # Check for common exit code patterns in string response
    exit_code = 1 if re.search(r'Exit code [1-9]|exit code [1-9]|exited with', response_text) else 0

if not command:
    sys.exit(0)

signal_type = None
signal_detail = None

# --- Detect git reverts (exclude --staged which is intentional unstaging) ---
if re.search(r'git\s+restore\s+', command) and not re.search(r'--staged', command):
    signal_type = 'revert'
    signal_detail = 'File reverted with git restore'
elif re.search(r'git\s+checkout\s+--\s+', command):
    signal_type = 'revert'
    signal_detail = 'File reverted with git checkout'
elif re.search(r'git\s+reset\s+--hard', command):
    signal_type = 'revert'
    signal_detail = 'Hard reset'

# --- Detect failures by exit code (not output text) ---
elif exit_code != 0:
    if re.search(r'(npm\s+test|pnpm\s+test|yarn\s+test|bun\s+test|pytest|go\s+test|cargo\s+test|vitest|jest)', command):
        signal_type = 'test_failure'
        signal_detail = 'Test suite failed'
    elif re.search(r'(lint|eslint|ruff\s+check|clippy|golangci)', command):
        signal_type = 'lint_failure'
        signal_detail = 'Lint check failed'
    elif re.search(r'(typecheck|tsc|mypy|go\s+vet|cargo\s+check)', command):
        signal_type = 'typecheck_failure'
        signal_detail = 'Type check failed'

if signal_type:
    project_dir = os.environ.get('CLAUDE_PROJECT_DIR', '.')
    signals_file = os.path.join(project_dir, '.claude', 'signals.jsonl')
    os.makedirs(os.path.dirname(signals_file), exist_ok=True)

    # Scrub secrets from command before logging
    safe_command = command[:200]
    safe_command = re.sub(r'(Bearer\s+)\S+', r'\1[REDACTED]', safe_command)
    safe_command = re.sub(r'(-u\s+)\S+:\S+', r'\1[REDACTED]', safe_command)
    safe_command = re.sub(r'(token[=:]\s*)\S+', r'\1[REDACTED]', safe_command, flags=re.IGNORECASE)
    safe_command = re.sub(r'(password[=:]\s*)\S+', r'\1[REDACTED]', safe_command, flags=re.IGNORECASE)
    safe_command = re.sub(r'(sk-|ghp_|gho_|glpat-|xoxb-)\S+', '[REDACTED]', safe_command)

    # Capture output snippet for failure signals (helps /retrospective identify root cause)
    snippet = ''
    if signal_type in ('test_failure', 'lint_failure', 'typecheck_failure'):
        snippet = response_text[:500]
        # Scrub secrets from snippet too
        snippet = re.sub(r'(Bearer\s+)\S+', r'\1[REDACTED]', snippet)
        snippet = re.sub(r'(sk-|ghp_|gho_|glpat-|xoxb-)\S+', '[REDACTED]', snippet)

    entry = {
        'timestamp': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        'type': signal_type,
        'detail': signal_detail,
        'command': safe_command
    }
    if snippet:
        entry['snippet'] = snippet

    # Cap file size at 100KB — keep last 200 lines if exceeded
    try:
        if os.path.exists(signals_file) and os.path.getsize(signals_file) > 100_000:
            with open(signals_file) as f:
                lines = f.readlines()
            with open(signals_file, 'w') as f:
                f.writelines(lines[-200:])
    except OSError:
        pass

    with open(signals_file, 'a') as f:
        f.write(json.dumps(entry) + '\n')
" || true
