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
RECONFIGURE_MODE=false

# Wizard schema version — bump when new questions are added so that
# `--update` can detect old Section 10 output and prompt the user to
# rerun the wizard.
WIZARD_SCHEMA_VERSION=2

# CCK_SRC comes from install.sh (--src=X flag or env var). Also accept --src=X
# directly when setup.sh is invoked standalone.
CCK_SRC="${CCK_SRC:-direct}"

STYLE_FLAG=""
RESPONSE_STYLE_OVERRIDE=""
DRY_RUN=false
ADVANCED_FLAG=false
CUSTOM_MODEL=""
SKIP_AGENTS=""        # comma-separated agent names to skip
SKIP_MCP=false
SKIP_SECTION10=false
for arg in "$@"; do
  case "$arg" in
    --skip-wizard) SKIP_WIZARD=true ;;
    --update) UPDATE_MODE=true; SKIP_WIZARD=true ;;
    --reconfigure) RECONFIGURE_MODE=true ;;  # rerun wizard only; keep files
    --dry-run|--preview) DRY_RUN=true; SKIP_WIZARD=true ;;  # report only
    --advanced) ADVANCED_FLAG=true ;;         # unlock power-user options
    --style=*) STYLE_FLAG="${arg#--style=}" ;;  # concise | balanced | beginner
    --model=*) CUSTOM_MODEL="${arg#--model=}" ;;  # sonnet | opus | haiku | opusplan
    --no-mcp) SKIP_MCP=true ;;
    --no-section) SKIP_SECTION10=true ;;
    --skip-agents=*) SKIP_AGENTS="${arg#--skip-agents=}" ;;
    --src=*) CCK_SRC="${arg#--src=}" ;;
    --*) ;; # unknown flag — ignore instead of treating as target dir
    *) TARGET_DIR="$arg" ;;
  esac
done

# --style=X takes effect regardless of --skip-wizard. Normalised once here
# so both the interactive wizard (via prompt_response_style) and the
# skip-wizard path both honour it.
if [ -n "$STYLE_FLAG" ]; then
  case "$STYLE_FLAG" in
    concise|balanced|beginner) RESPONSE_STYLE_OVERRIDE="$STYLE_FLAG" ;;
    *)
      # Unknown / deprecated value (e.g. the removed "verbose"). Warn and
      # fall back to balanced.
      RESPONSE_STYLE_OVERRIDE="balanced"
      STYLE_FLAG="balanced"  # keep prompt_response_style in sync
      ;;
  esac
fi

# --model=X validation. Reject unknown values so we never write a broken
# config to settings.json (Claude Code refuses to start with a bogus
# model id). Silently ignore with a warning — don't abort the install.
if [ -n "$CUSTOM_MODEL" ]; then
  case "$CUSTOM_MODEL" in
    sonnet|opus|haiku|opusplan) ;;
    *)
      printf '\033[33m[WARN]\033[0m unknown --model=%s (expected sonnet|opus|haiku|opusplan) — ignoring\n' "$CUSTOM_MODEL" >&2
      CUSTOM_MODEL=""
      ;;
  esac
fi

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

# ─── Advanced options (power users) ───
# Walked when the user answers Y to "Customize advanced options?" or when
# --advanced is on the command line. Each answer overrides install-time
# defaults without touching the standard wizard experience.
prompt_advanced_options() {
  echo ""
  echo -e "  ${BOLD}Advanced options${RESET} ${DIM}(press Enter to accept each default)${RESET}"

  # Main session model
  if [ -z "$CUSTOM_MODEL" ]; then
    echo ""
    echo -e "  ${BOLD}Main session model?${RESET}"
    echo -e "    1) ${BOLD}opusplan${RESET}  — Opus in plan mode, Sonnet in execution ${DIM}[default, recommended]${RESET}"
    echo -e "    2) sonnet    — Sonnet 4.6 everywhere"
    echo -e "    3) opus      — Opus 4.6 everywhere ${DIM}(most expensive)${RESET}"
    echo -e "    4) haiku     — Haiku 4.5 everywhere ${DIM}(cheapest, weakest on architecture)${RESET}"
    printf "  Choice [${BOLD}1${RESET}]: "
    read -r MODEL_CHOICE
    case "${MODEL_CHOICE:-1}" in
      2) CUSTOM_MODEL="sonnet" ;;
      3) CUSTOM_MODEL="opus" ;;
      4) CUSTOM_MODEL="haiku" ;;
      *) CUSTOM_MODEL="opusplan" ;;
    esac
  fi

  # Skip specific sub-agents
  echo ""
  echo -e "  ${BOLD}Sub-agents${RESET} ${DIM}(skip agents you don't need)${RESET}"
  echo -e "  Installed by default: code-reviewer, security-reviewer, test-runner, accessibility-reviewer, researcher"
  printf "  Skip any? ${DIM}(comma-separated names, or Enter for none)${RESET}: "
  read -r SKIP_AGENTS_INPUT
  [ -n "$SKIP_AGENTS_INPUT" ] && SKIP_AGENTS="$SKIP_AGENTS_INPUT"

  # MCP servers
  echo ""
  printf "  Skip MCP servers (Playwright + Context7 in .claude/mcp.json)? [y/${BOLD}N${RESET}]: "
  read -r SKIP_MCP_INPUT
  case "${SKIP_MCP_INPUT:-n}" in
    y|Y|yes|YES) SKIP_MCP=true ;;
  esac

  # Skip Section 10 entirely
  echo ""
  printf "  Skip CLAUDE.md Project-Specific Configuration (I'll write it myself)? [y/${BOLD}N${RESET}]: "
  read -r SKIP_SECTION_INPUT
  case "${SKIP_SECTION_INPUT:-n}" in
    y|Y|yes|YES) SKIP_SECTION10=true ;;
  esac
}

# ─── Substantive questions about the project ───
# Five short questions that measurably improve reviewer output quality.
# Each defaults to "skip/none" so existing users pressing Enter through
# the wizard get identical behaviour to before. Only asked when
# CCK_ASK_EXTRAS=true, which is set by a top-level "Quick questions?" toggle.
PROJECT_DB=""
PROJECT_AUTH=""
PROJECT_DEPLOY=""
PROJECT_USES_LLM=""
PROJECT_SECRETS=""

prompt_substantive_questions() {
  [ "${CCK_ASK_EXTRAS:-false}" = "true" ] || return
  echo ""
  echo -e "  ${BOLD}A few more details${RESET} ${DIM}(each is optional — press Enter to skip)${RESET}"

  # Database
  echo ""
  echo -e "  ${BOLD}Database?${RESET}"
  echo -e "    1) Postgres   2) MySQL   3) SQLite   4) MongoDB   5) DynamoDB"
  echo -e "    6) Redis-only   7) Other   ${DIM}[Enter = none]${RESET}"
  printf "  Choice: "
  read -r DB_CHOICE
  case "${DB_CHOICE:-0}" in
    1) PROJECT_DB="Postgres" ;;
    2) PROJECT_DB="MySQL" ;;
    3) PROJECT_DB="SQLite" ;;
    4) PROJECT_DB="MongoDB" ;;
    5) PROJECT_DB="DynamoDB" ;;
    6) PROJECT_DB="Redis (cache/queue)" ;;
    7) printf "  Name: "; read -r PROJECT_DB ;;
    *) PROJECT_DB="" ;;
  esac

  # Auth
  echo ""
  echo -e "  ${BOLD}Auth / identity?${RESET}"
  echo -e "    1) NextAuth.js   2) Clerk   3) Auth0   4) Supabase Auth"
  echo -e "    5) AWS Cognito   6) Custom JWT   7) Session cookies   ${DIM}[Enter = none]${RESET}"
  printf "  Choice: "
  read -r AUTH_CHOICE
  case "${AUTH_CHOICE:-0}" in
    1) PROJECT_AUTH="NextAuth.js" ;;
    2) PROJECT_AUTH="Clerk" ;;
    3) PROJECT_AUTH="Auth0" ;;
    4) PROJECT_AUTH="Supabase Auth" ;;
    5) PROJECT_AUTH="AWS Cognito" ;;
    6) PROJECT_AUTH="Custom JWT" ;;
    7) PROJECT_AUTH="Session cookies" ;;
    *) PROJECT_AUTH="" ;;
  esac

  # Deployment
  echo ""
  echo -e "  ${BOLD}Deployment target?${RESET}"
  echo -e "    1) Vercel   2) Railway   3) Fly.io   4) AWS"
  echo -e "    5) GCP   6) Azure   7) Self-hosted / VPS   ${DIM}[Enter = none]${RESET}"
  printf "  Choice: "
  read -r DEPLOY_CHOICE
  case "${DEPLOY_CHOICE:-0}" in
    1) PROJECT_DEPLOY="Vercel" ;;
    2) PROJECT_DEPLOY="Railway" ;;
    3) PROJECT_DEPLOY="Fly.io" ;;
    4) PROJECT_DEPLOY="AWS" ;;
    5) PROJECT_DEPLOY="GCP" ;;
    6) PROJECT_DEPLOY="Azure" ;;
    7) PROJECT_DEPLOY="Self-hosted" ;;
    *) PROJECT_DEPLOY="" ;;
  esac

  # LLM usage → auto-install claude-api skill guidance
  echo ""
  echo -e "  ${BOLD}Does this project call LLMs itself?${RESET} ${DIM}(Anthropic / OpenAI / LangChain etc.)${RESET}"
  printf "  [y/${BOLD}N${RESET}]: "
  read -r LLM_CHOICE
  case "${LLM_CHOICE:-n}" in
    y|Y|yes|YES) PROJECT_USES_LLM="yes" ;;
    *)           PROJECT_USES_LLM="" ;;
  esac

  # Secret management
  echo ""
  echo -e "  ${BOLD}How are secrets managed?${RESET}"
  echo -e "    1) .env (dotenv)   2) Platform env vars (Vercel / Railway etc.)"
  echo -e "    3) HashiCorp Vault   4) AWS Secrets Manager / Parameter Store"
  echo -e "    5) Doppler / Infisical   ${DIM}[Enter = skip]${RESET}"
  printf "  Choice: "
  read -r SECRETS_CHOICE
  case "${SECRETS_CHOICE:-0}" in
    1) PROJECT_SECRETS=".env file (dotenv) — must not be committed" ;;
    2) PROJECT_SECRETS="Platform env vars" ;;
    3) PROJECT_SECRETS="HashiCorp Vault" ;;
    4) PROJECT_SECRETS="AWS Secrets Manager" ;;
    5) PROJECT_SECRETS="Doppler / Infisical" ;;
    *) PROJECT_SECRETS="" ;;
  esac
}

# ─── Response-style wizard prompt ───
# Asks how terse Claude should be. Fewer tokens = cheaper sessions.
# Verbose mode was removed — it contradicted every other token-reduction
# default in this template. If someone really wants long explanations,
# they can edit Section 10 manually.
prompt_response_style() {
  # If the user passed --style=X, skip the interactive prompt entirely.
  if [ -n "${STYLE_FLAG:-}" ]; then
    case "$STYLE_FLAG" in
      concise|balanced|beginner) RESPONSE_STYLE="$STYLE_FLAG" ;;
      *)
        echo -e "  ${YELLOW}[WARN]${RESET} unknown --style=$STYLE_FLAG, falling back to balanced"
        RESPONSE_STYLE="balanced"
        ;;
    esac
    return
  fi
  echo ""
  echo -e "  ${BOLD}How should Claude respond?${RESET} ${DIM}(affects token cost per session)${RESET}"
  echo -e "    1) ${BOLD}Concise${RESET}  — short answers, minimal preamble. ${DIM}Least tokens. Recommended.${RESET}"
  echo -e "    2) ${BOLD}Balanced${RESET} — short but complete explanations. ${DIM}Middle ground.${RESET}"
  echo -e "    3) ${BOLD}Beginner${RESET} — plain language, no jargon. ${DIM}For non-developers.${RESET}"
  printf "  Choice [${BOLD}2${RESET}]: "
  read -r STYLE_CHOICE
  case "${STYLE_CHOICE:-2}" in
    1) RESPONSE_STYLE="concise" ;;
    3) RESPONSE_STYLE="beginner" ;;
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
- Verification output still required per CLAUDE.md §5 (non-negotiable).
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
- Still obey CLAUDE.md §5 verification — but explain the test output in plain words
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

# ─── Warn on commands whose binary isn't on PATH ───
# Validates detected/user-supplied command strings. First token is the
# binary name (or `./bin/foo` — local paths are skipped). Non-fatal: just
# prints a warning so the user knows Claude may hit a missing tool.
#
# The allow-list is deliberately broad: every tool the wizard may suggest
# is considered "plausibly installed later" and we don't warn about it.
# The warning only fires for genuinely unexpected binaries — typically
# from user-supplied custom commands in the manual wizard.
validate_command() {
  local label="$1"
  local cmd="$2"
  [ -z "$cmd" ] && return
  local bin
  bin=$(printf '%s' "$cmd" | awk '{print $1}')
  case "$bin" in
    ./*|/*|../*) return ;;  # explicit local path — don't check PATH
    # Stack-level runners
    make|gmake|just) return ;;
    # Node ecosystem
    node|npm|npx|pnpm|yarn|bun|deno|corepack) return ;;
    # Python ecosystem
    python|python3|pip|pip3|pipx|poetry|uv|pipenv|pytest|ruff|mypy|pyright|black|flake8|flask|uvicorn|gunicorn|django-admin|celery) return ;;
    # Go ecosystem
    go|gofmt|goimports|golangci-lint|staticcheck|dlv|air) return ;;
    # Rust ecosystem
    cargo|rustc|rustup|rustfmt|clippy-driver) return ;;
    # JVM (Java/Kotlin/Scala)
    java|javac|mvn|gradle|./gradlew|kotlin|kotlinc|sbt) return ;;
    # .NET
    dotnet|nuget|msbuild) return ;;
    # Ruby
    ruby|bundle|bundler|rake|rspec|rubocop|irb|rails|./bin/rails) return ;;
    # Elixir
    mix|iex|elixir|erl) return ;;
    # PHP
    php|composer|artisan|phpstan|phpcs|phpunit|symfony) return ;;
    # Test/build runners commonly shelled out to
    vitest|jest|playwright|cypress|mocha|tsc|esbuild|turbo|nx|vite|webpack|rollup) return ;;
    # Infra
    docker|docker-compose|podman|kubectl|terraform) return ;;
  esac
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo -e "  ${YELLOW}[WARN]${RESET} ${label}: \`${bin}\` not found on PATH (configure it later or ignore)"
  fi
}

# ─── Read a JSON key from package.json (no jq dependency) ───
# Pass the key via env var instead of interpolating into the Python source —
# prevents any future caller from accidentally enabling a script-injection
# path if the key ever comes from untrusted input.
pkg_script() {
  local key="$1"
  CCK_KEY="$key" python3 -c "
import json, os
try:
    d = json.load(open('package.json'))
    print(d.get('scripts', {}).get(os.environ.get('CCK_KEY', ''), ''))
except Exception:
    pass
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
RESPONSE_STYLE="${RESPONSE_STYLE_OVERRIDE:-balanced}"  # concise | balanced | beginner
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

  # Try to detect Python framework across pyproject.toml, requirements.txt,
  # setup.py. Populates CMD_DEV and sets PY_FRAMEWORK for starter matching.
  if [ -z "$CMD_DEV" ]; then
    PY_SOURCES=""
    [ -f "pyproject.toml" ] && PY_SOURCES="$PY_SOURCES pyproject.toml"
    [ -f "requirements.txt" ] && PY_SOURCES="$PY_SOURCES requirements.txt"
    [ -f "setup.py" ] && PY_SOURCES="$PY_SOURCES setup.py"
    if [ -n "$PY_SOURCES" ]; then
      if grep -qi "fastapi\|uvicorn" $PY_SOURCES 2>/dev/null; then
        CMD_DEV="uvicorn main:app --reload"
        PY_FRAMEWORK="fastapi"
      elif grep -qi "^django\|^Django" $PY_SOURCES 2>/dev/null || grep -qi '"django"' $PY_SOURCES 2>/dev/null; then
        CMD_DEV="python manage.py runserver"
        PY_FRAMEWORK="django"
      elif grep -qi "flask" $PY_SOURCES 2>/dev/null; then
        CMD_DEV="flask run --reload"
        PY_FRAMEWORK="flask"
      elif grep -qi "langchain\|llama_index\|anthropic\|openai" $PY_SOURCES 2>/dev/null; then
        CMD_DEV="python main.py"
        PY_FRAMEWORK="llm"
      fi
    fi
  fi

elif [ -f "deno.json" ] || [ -f "deno.jsonc" ]; then
  STACK="deno"
  PKG_MGR="deno"
  DETECTED=true
  CMD_DEV="deno task dev"
  CMD_TYPECHECK="deno check **/*.ts"
  CMD_LINT="deno lint"
  CMD_TEST="deno test"
  CMD_BUILD="deno compile"

elif [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
  # Bun-only project (no package.json — rare, but possible for single-file
  # scripts or bun workspaces with a bunfig.toml at root).
  STACK="bun"
  PKG_MGR="bun"
  DETECTED=true
  CMD_DEV="bun run dev"
  CMD_TYPECHECK="bun run typecheck"
  CMD_LINT="bun run lint"
  CMD_TEST="bun test"
  CMD_BUILD="bun run build"

elif [ -f "mix.exs" ]; then
  STACK="elixir"
  PKG_MGR="mix"
  DETECTED=true
  CMD_DEV="mix phx.server"
  CMD_TYPECHECK="mix dialyzer"
  CMD_LINT="mix credo"
  CMD_TEST="mix test"
  CMD_BUILD="mix compile"
  # Non-Phoenix projects
  if ! grep -q "phoenix" mix.exs 2>/dev/null; then
    CMD_DEV="iex -S mix"
  fi

elif [ -f "Gemfile" ]; then
  STACK="ruby"
  PKG_MGR="bundler"
  DETECTED=true
  CMD_TEST="bundle exec rspec"
  CMD_LINT="bundle exec rubocop"
  CMD_BUILD=""
  if grep -qi "rails" Gemfile 2>/dev/null; then
    CMD_DEV="bin/rails server"
    CMD_TYPECHECK="bin/rails test:system"
  elif grep -qi "sinatra" Gemfile 2>/dev/null; then
    CMD_DEV="bundle exec rackup"
  else
    CMD_DEV="bundle exec ruby"
  fi

elif [ -f "pom.xml" ]; then
  STACK="java"
  PKG_MGR="maven"
  DETECTED=true
  CMD_DEV="mvn spring-boot:run"
  CMD_TYPECHECK="mvn compile"
  CMD_LINT="mvn checkstyle:check"
  CMD_TEST="mvn test"
  CMD_BUILD="mvn package"

elif [ -f "build.gradle" ] || [ -f "build.gradle.kts" ]; then
  STACK="java"  # covers both Java and Kotlin JVM projects
  PKG_MGR="gradle"
  DETECTED=true
  CMD_DEV="./gradlew bootRun"
  CMD_TYPECHECK="./gradlew compileJava"
  CMD_LINT="./gradlew check"
  CMD_TEST="./gradlew test"
  CMD_BUILD="./gradlew build"
  # Kotlin-specific tweaks
  if [ -f "build.gradle.kts" ]; then
    STACK="kotlin"
    CMD_TYPECHECK="./gradlew compileKotlin"
  fi

elif ls *.csproj >/dev/null 2>&1 || ls *.sln >/dev/null 2>&1; then
  STACK="dotnet"
  PKG_MGR="dotnet"
  DETECTED=true
  CMD_DEV="dotnet run"
  CMD_TYPECHECK="dotnet build --no-restore"
  CMD_LINT="dotnet format --verify-no-changes"
  CMD_TEST="dotnet test"
  CMD_BUILD="dotnet build --configuration Release"

elif [ -f "composer.json" ]; then
  STACK="php"
  PKG_MGR="composer"
  DETECTED=true
  CMD_LINT="vendor/bin/phpcs"
  CMD_TEST="vendor/bin/phpunit"
  CMD_BUILD="composer install --no-dev --optimize-autoloader"
  if grep -qi "laravel" composer.json 2>/dev/null; then
    CMD_DEV="php artisan serve"
    CMD_TYPECHECK="vendor/bin/phpstan analyse"
  elif grep -qi "symfony" composer.json 2>/dev/null; then
    CMD_DEV="symfony server:start"
    CMD_TYPECHECK="vendor/bin/phpstan analyse"
  else
    CMD_DEV="php -S localhost:8000"
    CMD_TYPECHECK=""
  fi

elif [ -f "Makefile" ] || [ -f "makefile" ]; then
  # Makefile-only project (no recognisable language marker). Treat as
  # "other" but populate commands from make targets if they exist.
  STACK="make"
  PKG_MGR=""
  DETECTED=true
  MF="Makefile"
  [ -f "makefile" ] && MF="makefile"
  grep -q "^dev:" "$MF" 2>/dev/null && CMD_DEV="make dev"
  grep -q "^test:" "$MF" 2>/dev/null && CMD_TEST="make test"
  grep -q "^lint:" "$MF" 2>/dev/null && CMD_LINT="make lint"
  grep -q "^build:" "$MF" 2>/dev/null && CMD_BUILD="make build"
  grep -q "^check:" "$MF" 2>/dev/null && CMD_TYPECHECK="make check"
fi

# ─── Orthogonal detection: codebase size ───
# For >500 source files we nudge toward SocratiCode MCP (semantic search
# over the graph). Cheap file count — bounded via `find -type f` with a
# soft cap to avoid walking huge node_modules or vendor dirs.
SOURCE_FILE_COUNT=0
if command -v find >/dev/null 2>&1; then
  SOURCE_FILE_COUNT=$(find . -type f \
    \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \
       -o -name "*.py" -o -name "*.go" -o -name "*.rs" -o -name "*.java" \
       -o -name "*.kt" -o -name "*.rb" -o -name "*.ex" -o -name "*.exs" \
       -o -name "*.php" -o -name "*.cs" -o -name "*.swift" \) \
    ! -path "./node_modules/*" ! -path "./.git/*" ! -path "./target/*" \
    ! -path "./dist/*" ! -path "./build/*" ! -path "./vendor/*" \
    ! -path "./.venv/*" ! -path "./venv/*" \
    2>/dev/null | head -1001 | wc -l | tr -d ' ')
fi
LARGE_CODEBASE=false
[ "${SOURCE_FILE_COUNT:-0}" -gt 500 ] 2>/dev/null && LARGE_CODEBASE=true

# ─── Orthogonal detection: CODEOWNERS ───
# Repos with ownership rules should signal reviewers to respect them.
HAS_CODEOWNERS=false
if [ -f "CODEOWNERS" ] || [ -f ".github/CODEOWNERS" ] || [ -f "docs/CODEOWNERS" ]; then
  HAS_CODEOWNERS=true
fi

# ─── Orthogonal detection: monorepo markers ───
# Monorepo is a flag, not a stack. Affects wording in Section 10 and
# signals to reviewers that workspace-scoped commands may be needed.
IS_MONOREPO=false
MONOREPO_TOOL=""
if [ -f "pnpm-workspace.yaml" ] || [ -f "pnpm-workspace.yml" ]; then
  IS_MONOREPO=true
  MONOREPO_TOOL="pnpm workspaces"
elif [ -f "turbo.json" ]; then
  IS_MONOREPO=true
  MONOREPO_TOOL="Turborepo"
elif [ -f "nx.json" ]; then
  IS_MONOREPO=true
  MONOREPO_TOOL="Nx"
elif [ -f "lerna.json" ]; then
  IS_MONOREPO=true
  MONOREPO_TOOL="Lerna"
fi

# ─── Show Detection Results / Run Wizard ───

# ─── Detect specific framework within the stack (runs always, not just in interactive mode) ───
# Populates NODE_FRAMEWORK / PY_FRAMEWORK so Section 10 can include a
# specific Stack line even when no matching starter file exists.
NODE_FRAMEWORK="${NODE_FRAMEWORK:-}"
if [ "$STACK" = "node" ] && [ -f "package.json" ]; then
  if grep -q '"next"' package.json 2>/dev/null; then
    NODE_FRAMEWORK="Next.js"
  elif grep -q '"@remix-run/' package.json 2>/dev/null; then
    NODE_FRAMEWORK="Remix"
  elif grep -q '"@sveltejs/kit"' package.json 2>/dev/null; then
    NODE_FRAMEWORK="SvelteKit"
  elif grep -q '"astro"' package.json 2>/dev/null; then
    NODE_FRAMEWORK="Astro"
  elif grep -q '"nuxt"' package.json 2>/dev/null; then
    NODE_FRAMEWORK="Nuxt"
  elif grep -q '"vite"' package.json 2>/dev/null; then
    if grep -q '"react"' package.json 2>/dev/null; then
      NODE_FRAMEWORK="Vite + React"
    elif grep -q '"vue"' package.json 2>/dev/null; then
      NODE_FRAMEWORK="Vite + Vue"
    else
      NODE_FRAMEWORK="Vite"
    fi
  fi
fi

if { [ "$DETECTED" = true ] && [ "$SKIP_WIZARD" = false ]; } || [ "$DRY_RUN" = true ]; then
  if [ "$DRY_RUN" = true ]; then
    echo -e "  ${BOLD}Dry run — nothing will be written.${RESET}"
    echo ""
  fi
  echo -e "  ${GREEN}Auto-detected:${RESET}"
  echo -e "    Project:  ${BOLD}$PROJECT_NAME${RESET}"
  echo -e "    Stack:    ${BOLD}${STACK:-<none>}${RESET}"
  [ -n "$NODE_FRAMEWORK" ] && echo -e "    Framework:${BOLD} $NODE_FRAMEWORK${RESET}"
  [ -n "${PY_FRAMEWORK:-}" ] && echo -e "    Framework:${BOLD} $PY_FRAMEWORK${RESET}"
  [ -n "$PKG_MGR" ] && echo -e "    Package:  ${BOLD}$PKG_MGR${RESET}"
  [ "$IS_MONOREPO" = true ] && echo -e "    Monorepo: ${BOLD}$MONOREPO_TOOL${RESET}"
  [ "$HAS_CODEOWNERS" = true ] && echo -e "    Ownership:${BOLD} CODEOWNERS detected${RESET}"
  [ "$LARGE_CODEBASE" = true ] && echo -e "    Size:     ${BOLD}${SOURCE_FILE_COUNT}+ source files${RESET} ${DIM}(consider SocratiCode MCP)${RESET}"
  [ -n "$CMD_DEV" ] && echo -e "    Dev:      ${DIM}$CMD_DEV${RESET}"
  [ -n "$CMD_TYPECHECK" ] && echo -e "    Typecheck:${DIM} $CMD_TYPECHECK${RESET}"
  [ -n "$CMD_LINT" ] && echo -e "    Lint:     ${DIM}$CMD_LINT${RESET}"
  [ -n "$CMD_TEST" ] && echo -e "    Test:     ${DIM}$CMD_TEST${RESET}"
  [ -n "$CMD_BUILD" ] && echo -e "    Build:    ${DIM}$CMD_BUILD${RESET}"
  echo ""

  # Validate each detected command — non-fatal warnings only.
  validate_command "Dev"       "$CMD_DEV"
  validate_command "Typecheck" "$CMD_TYPECHECK"
  validate_command "Lint"      "$CMD_LINT"
  validate_command "Test"      "$CMD_TEST"
  validate_command "Build"     "$CMD_BUILD"

  if [ "$DRY_RUN" = true ]; then
    echo ""
    echo -e "  ${BOLD}Would write:${RESET}"
    echo -e "    CLAUDE.md (Project-Specific Configuration section)"
    echo -e "    .claude/settings.json, .claude/mcp.json"
    echo -e "    .claude/agents/*, .claude/commands/*, .claude/skills/*"
    echo -e "    .claude/hooks/*.sh"
    echo -e "    primer.md, gotchas.md, patterns.md, decisions.md, CHEATSHEET.md"
    [ "$STACK" = "node" ] && echo -e "    .npmrc (supply chain guards)"
    echo ""
    echo -e "  ${DIM}(dry run — no files touched. Re-run without --dry-run to install.)${RESET}"
    exit 0
  fi
fi

if [ "$DETECTED" = true ] && [ "$SKIP_WIZARD" = false ]; then
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
        if [ "$NODE_FRAMEWORK" = "Next.js" ]; then
          STARTER_FILE="$TMP_DIR/starters/nextjs.md"
          STARTER_NAME="Next.js"
        fi
        ;;
      python)
        if [ "${PY_FRAMEWORK:-}" = "fastapi" ]; then
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
    echo -e "  ${DIM}Code conventions Claude should enforce (one line).${RESET}"
    echo -e "  ${DIM}Examples:${RESET}"
    echo -e "  ${DIM}  - strict TypeScript, no any${RESET}"
    echo -e "  ${DIM}  - Server Components by default, 'use client' only when needed${RESET}"
    echo -e "  ${DIM}  - all errors wrapped with context; no bare exceptions${RESET}"
    printf "  Conventions (optional): "
    read -r CONVENTIONS

    # Optional substantive questions (DB, auth, deploy, LLM, secrets).
    # Default N so the hot path stays fast for users mashing Enter.
    echo ""
    printf "  Answer 5 quick questions about DB / auth / deploy / secrets? ${DIM}(improves reviewer output)${RESET} [y/${BOLD}N${RESET}]: "
    read -r ASK_EXTRAS
    case "${ASK_EXTRAS:-n}" in
      y|Y|yes|YES) CCK_ASK_EXTRAS=true; prompt_substantive_questions ;;
    esac

    # Optional advanced / power-user options. Default N.
    if [ "$ADVANCED_FLAG" != true ]; then
      echo ""
      printf "  Customize advanced options (model, agents, MCP)? [y/${BOLD}N${RESET}]: "
      read -r ASK_ADV
      case "${ASK_ADV:-n}" in
        y|Y|yes|YES) prompt_advanced_options ;;
      esac
    else
      prompt_advanced_options
    fi

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
  echo -e "  ${DIM}Code conventions Claude should enforce (one line).${RESET}"
  echo -e "  ${DIM}Examples:${RESET}"
  echo -e "  ${DIM}  - strict TypeScript, no any${RESET}"
  echo -e "  ${DIM}  - Server Components by default${RESET}"
  echo -e "  ${DIM}  - 100-char lines, trailing commas, single quotes${RESET}"
  printf "  Conventions (optional): "
  read -r CONVENTIONS

  # 5. Optional substantive questions (same as detected-path)
  echo ""
  printf "  Answer 5 quick questions about DB / auth / deploy / secrets? ${DIM}(improves reviewer output)${RESET} [y/${BOLD}N${RESET}]: "
  read -r ASK_EXTRAS
  case "${ASK_EXTRAS:-n}" in
    y|Y|yes|YES) CCK_ASK_EXTRAS=true; prompt_substantive_questions ;;
  esac

  # 6. Optional advanced / power-user options (same as detected-path).
  if [ "$ADVANCED_FLAG" != true ]; then
    echo ""
    printf "  Customize advanced options (model, agents, MCP)? [y/${BOLD}N${RESET}]: "
    read -r ASK_ADV
    case "${ASK_ADV:-n}" in
      y|Y|yes|YES) prompt_advanced_options ;;
    esac
  else
    prompt_advanced_options
  fi

  # 7. Response style
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

if [ "$RECONFIGURE_MODE" = true ]; then
  echo -e "  ${BOLD}Reconfiguring${RESET} in: ${BOLD}$(pwd)${RESET}"
  echo -e "${DIM}  Wizard rerun only — regenerates CLAUDE.md Project-Specific Configuration.${RESET}"
  echo -e "${DIM}  All other files untouched.${RESET}"
  echo ""
  # No file copy in reconfigure mode — fall through to the configure block.

elif [ "$UPDATE_MODE" = true ]; then
  echo -e "  ${BOLD}Updating${RESET} in: ${BOLD}$(pwd)${RESET}"
  echo -e "${DIM}  Preserving: CLAUDE.md, primer.md, gotchas.md, patterns.md, decisions.md, settings.json, mcp.json${RESET}"
  echo ""

  # Detect stale wizard output. If CLAUDE.md has no version stamp, or a
  # stamp older than WIZARD_SCHEMA_VERSION, the user installed before new
  # wizard questions were added. Warn and point them at --reconfigure.
  if [ -f "CLAUDE.md" ]; then
    EXISTING_SCHEMA=$(grep -oE 'cck:wizard-schema=[0-9]+' CLAUDE.md 2>/dev/null | head -1 | cut -d= -f2)
    # Only warn if Section 10/11 appears to be populated (i.e. the user ran
    # the wizard at some point). If it still has the template stubs, leave
    # them alone — the user hasn't configured anything yet.
    if ! grep -q "<!-- Example:" CLAUDE.md 2>/dev/null; then
      if [ -z "$EXISTING_SCHEMA" ] || [ "$EXISTING_SCHEMA" -lt "$WIZARD_SCHEMA_VERSION" ] 2>/dev/null; then
        echo -e "  ${YELLOW}[NOTE]${RESET} Your CLAUDE.md Project-Specific Configuration was generated by an"
        echo -e "         older wizard schema (${EXISTING_SCHEMA:-none} < current ${WIZARD_SCHEMA_VERSION})."
        echo -e "         New wizard questions are available. Re-run to apply them:"
        echo -e "         ${BOLD}bash setup.sh --reconfigure${RESET}"
        echo ""
      fi
    fi
  fi

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

  # Update all hook scripts (overwrite with latest, preserve exec bit)
  mkdir -p .claude/hooks
  for hook in "$TMP_DIR"/.claude/hooks/*.sh; do
    [ -f "$hook" ] || continue
    copy_force "$hook" ".claude/hooks/$(basename "$hook")"
    chmod +x ".claude/hooks/$(basename "$hook")" 2>/dev/null || true
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
  if [ "$SKIP_MCP" = true ]; then
    echo -e "  ${DIM}[SKIP]${RESET} .claude/mcp.json (advanced: --no-mcp)"
  else
    copy_safe "$TMP_DIR/.claude/mcp.json" ".claude/mcp.json"
  fi

  # Agents (individual, never overwrite). Honour --skip-agents=a,b,c.
  mkdir -p .claude/agents
  for agent in "$TMP_DIR"/.claude/agents/*.md; do
    [ -f "$agent" ] || continue
    agent_name=$(basename "$agent" .md)
    if [ -n "$SKIP_AGENTS" ] && printf ',%s,' "$SKIP_AGENTS" | grep -qF ",${agent_name},"; then
      echo -e "  ${DIM}[SKIP]${RESET} .claude/agents/${agent_name}.md (advanced: --skip-agents)"
      continue
    fi
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

  # Hook scripts (individual, never overwrite, preserve exec bit)
  # settings.json references these — if they're missing, every session errors.
  mkdir -p .claude/hooks
  for hook in "$TMP_DIR"/.claude/hooks/*.sh; do
    [ -f "$hook" ] || continue
    copy_safe "$hook" ".claude/hooks/$(basename "$hook")"
    chmod +x ".claude/hooks/$(basename "$hook")" 2>/dev/null || true
  done
fi

# ─── Configure from detection / wizard answers (skip in update mode) ───

# Run the configure block on any fresh install or explicit --reconfigure.
# Previously required at least one detected command — but that left empty
# fixtures with the unpopulated template stubs. Now an empty install still
# gets a minimal version-stamped section (just the heading + Architecture
# placeholder + response-style block).
if [ "$SKIP_SECTION10" = true ]; then
  echo -e "  ${DIM}[SKIP]${RESET} CLAUDE.md Project-Specific Configuration (advanced: --no-section)"
elif [ "$UPDATE_MODE" != true ] || [ "$RECONFIGURE_MODE" = true ]; then

  # If a starter config was chosen, use it directly
  if [ -n "${USE_STARTER_CONFIG:-}" ] && [ -f "$USE_STARTER_CONFIG" ]; then
    CONFIG_SECTION=$(cat "$USE_STARTER_CONFIG")
    # Starters historically hardcoded "## 10." as the section heading. Normalize
    # that to the placeholder so the same substitution logic handles both paths
    # when CLAUDE.md is renumbered.
    CONFIG_SECTION=$(printf '%s' "$CONFIG_SECTION" | sed 's/^## [0-9]\{1,2\}\. Project-Specific Configuration/## __SECNUM__. Project-Specific Configuration/')
    if [ -n "$CONVENTIONS" ]; then
      CONFIG_SECTION="$CONFIG_SECTION\n\n### Additional Conventions\n$CONVENTIONS"
    fi
  else
    # Build config from auto-detected/wizard values.
    # The section heading's number is discovered dynamically from the
    # template (see the grep below) so renumbering CLAUDE.md doesn't
    # break the installer. We placeholder it here and substitute later.
    CONFIG_SECTION="## __SECNUM__. Project-Specific Configuration"
    CONFIG_SECTION="$CONFIG_SECTION\n"

    if [ -n "$PROJECT_NAME" ]; then
      CONFIG_SECTION="$CONFIG_SECTION\n### Project\n$PROJECT_NAME\n"
    fi

    # Compose the Stack line, using the specific framework when known.
    STACK_LINE=""
    case "$STACK" in
      node)
        if [ -n "$NODE_FRAMEWORK" ]; then
          STACK_LINE="Node.js / TypeScript — $NODE_FRAMEWORK"
        else
          STACK_LINE="Node.js / TypeScript"
        fi
        ;;
      python)
        case "${PY_FRAMEWORK:-}" in
          fastapi) STACK_LINE="Python — FastAPI" ;;
          django)  STACK_LINE="Python — Django" ;;
          flask)   STACK_LINE="Python — Flask" ;;
          llm)     STACK_LINE="Python — LLM / AI (LangChain / Anthropic / OpenAI SDK)" ;;
          *)       STACK_LINE="Python" ;;
        esac
        ;;
      go)      STACK_LINE="Go" ;;
      rust)    STACK_LINE="Rust" ;;
      deno)    STACK_LINE="Deno / TypeScript" ;;
      bun)     STACK_LINE="Bun / TypeScript" ;;
      elixir)  STACK_LINE="Elixir" ;;
      ruby)    STACK_LINE="Ruby" ;;
      java)    STACK_LINE="Java (JVM)" ;;
      kotlin)  STACK_LINE="Kotlin (JVM)" ;;
      dotnet)  STACK_LINE=".NET / C#" ;;
      php)     STACK_LINE="PHP" ;;
      make)    STACK_LINE="Make-driven project" ;;
    esac
    if [ -n "$STACK_LINE" ]; then
      CONFIG_SECTION="$CONFIG_SECTION\n### Stack\n$STACK_LINE"
      if [ "$IS_MONOREPO" = true ]; then
        CONFIG_SECTION="$CONFIG_SECTION ($MONOREPO_TOOL monorepo — prefer workspace-scoped commands where possible)"
      fi
      CONFIG_SECTION="$CONFIG_SECTION\n"
    fi

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

  # Infrastructure + Ownership are appended to BOTH the starter and the
  # auto-generated paths. Starter files don't know about the user's DB /
  # auth / deploy answers, so these blocks must be added post-hoc.
  if [ -n "$PROJECT_DB" ] || [ -n "$PROJECT_AUTH" ] || [ -n "$PROJECT_DEPLOY" ] || [ -n "$PROJECT_SECRETS" ] || [ -n "$PROJECT_USES_LLM" ]; then
    CONFIG_SECTION="$CONFIG_SECTION\n\n### Infrastructure"
    [ -n "$PROJECT_DB" ]      && CONFIG_SECTION="$CONFIG_SECTION\n- **Database:** $PROJECT_DB — reviewers should flag unparameterized queries and migration safety."
    [ -n "$PROJECT_AUTH" ]    && CONFIG_SECTION="$CONFIG_SECTION\n- **Auth:** $PROJECT_AUTH — every protected route must verify identity; security-reviewer should audit session handling."
    [ -n "$PROJECT_DEPLOY" ]  && CONFIG_SECTION="$CONFIG_SECTION\n- **Deployment:** $PROJECT_DEPLOY"
    [ -n "$PROJECT_SECRETS" ] && CONFIG_SECTION="$CONFIG_SECTION\n- **Secrets:** $PROJECT_SECRETS — never commit secrets; never log them; never include them in error messages."
    [ -n "$PROJECT_USES_LLM" ] && CONFIG_SECTION="$CONFIG_SECTION\n- **LLM integration:** this project calls LLMs. Wrap API keys as env vars, handle rate limits, and expect non-deterministic output in tests."
    CONFIG_SECTION="$CONFIG_SECTION\n"
  fi

  if [ "$HAS_CODEOWNERS" = true ]; then
    CONFIG_SECTION="$CONFIG_SECTION\n\n### Ownership\nThis repo has a CODEOWNERS file. Respect ownership rules when touching shared modules — verify the owning team signs off on cross-cutting changes.\n"
  fi

  # Append response-style block (works for both starter and auto-gen paths —
  # real newlines are tolerated by both echo -e and printf '%s\n')
  STYLE_BLOCK=$(build_response_style_block)
  CONFIG_SECTION="${CONFIG_SECTION}
${STYLE_BLOCK}"

  # Replace the Project-Specific Configuration section in CLAUDE.md.
  #
  # The section number is discovered dynamically (was §10, now §11 after
  # the Execution Loop addition). Previously this grep was hard-coded to
  # §10 and silently skipped the replacement after renumbering, causing
  # every install to ship with the unpopulated template Section.
  if [ -f "CLAUDE.md" ]; then
    # Match any "## N. Project-Specific Configuration" heading, capture N.
    SEC_HEADER=$(grep -n '^## [0-9]\{1,2\}\. Project-Specific Configuration' CLAUDE.md | head -1)

    # W9 — smart merge: if CLAUDE.md exists but has no Project-Specific
    # Configuration section, append one at the end instead of silently
    # warning. Only runs on fresh installs + --reconfigure (not --update,
    # which is already short-circuited above).
    if [ -z "$SEC_HEADER" ]; then
      # Guess the next section number. Find the highest existing `## N.`
      # heading and add 1. Default to 11 if we can't parse any.
      LAST_SEC_NUM=$(grep -oE '^## [0-9]+\.' CLAUDE.md | grep -oE '[0-9]+' | sort -n | tail -1)
      if [ -n "$LAST_SEC_NUM" ]; then
        NEW_SEC_NUM=$((LAST_SEC_NUM + 1))
      else
        NEW_SEC_NUM=11
      fi
      # Substitute the generated block's placeholder with the computed number.
      CONFIG_SECTION=${CONFIG_SECTION//__SECNUM__/$NEW_SEC_NUM}
      # Back up before any destructive write.
      cp CLAUDE.md CLAUDE.md.bak 2>/dev/null || true
      # Ensure trailing newline on the existing file, then append.
      printf '\n' >> CLAUDE.md
      if [ -n "${USE_STARTER_CONFIG:-}" ]; then
        printf '%s\n' "$CONFIG_SECTION" >> CLAUDE.md
      else
        echo -e "$CONFIG_SECTION" >> CLAUDE.md
      fi
      printf '\n<!-- cck:wizard-schema=%s -->\n' "$WIZARD_SCHEMA_VERSION" >> CLAUDE.md
      echo -e "  ${GREEN}[APPENDED]${RESET} CLAUDE.md §${NEW_SEC_NUM} (Project-Specific Configuration — no matching heading found, added at end; backup at CLAUDE.md.bak)"
      SEC_HEADER=""  # skip the replacement block below
    fi

    # If the append path above ran, SEC_HEADER is empty and we're done.
    # Otherwise, fall through to the replace-in-place logic.
    if [ -n "$SEC_HEADER" ]; then
      SECTION_LINE=$(printf '%s' "$SEC_HEADER" | cut -d: -f1)
      SECTION_NUM=$(printf '%s' "$SEC_HEADER" | sed -n 's/^[0-9]*:## \([0-9]\{1,2\}\)\..*/\1/p')

      # Guard against a broken sed regex silently producing empty output,
      # which would write "## . Project-Specific Configuration" to CLAUDE.md.
      if [ -z "$SECTION_NUM" ]; then
        echo -e "  ${YELLOW}[WARN]${RESET} Could not parse section number from heading — skipping replacement"
      else
        # Substitute the placeholder in the generated block with the real number.
        CONFIG_SECTION=${CONFIG_SECTION//__SECNUM__/$SECTION_NUM}

        # Allow replacement when:
        #   - the section still has template stubs (fresh install), OR
        #   - we're explicitly in --reconfigure mode (user asked to regenerate)
        if [ "$RECONFIGURE_MODE" = true ] || grep -q "<!-- Example:" CLAUDE.md 2>/dev/null || grep -q "<!-- Describe directory" CLAUDE.md 2>/dev/null; then
          # Find the END of the target section: the next `^## ` heading after
          # SECTION_LINE. Everything from SECTION_LINE up to (but not including)
          # that next heading is what we replace. Content after the next
          # heading is preserved — the previous implementation silently
          # truncated all subsequent sections, destroying any user-added
          # sections past Project-Specific Configuration.
          NEXT_REL=$(tail -n +$((SECTION_LINE + 1)) CLAUDE.md | grep -n '^## ' | head -1 | cut -d: -f1)
          if [ -n "$NEXT_REL" ]; then
            END_LINE=$(( SECTION_LINE + NEXT_REL ))
          else
            END_LINE=""  # target section runs to EOF
          fi

          # Safety backup — destructive write, one chance to recover.
          cp CLAUDE.md CLAUDE.md.bak 2>/dev/null || true

          head -n $((SECTION_LINE - 1)) CLAUDE.md > CLAUDE.md.tmp
          if [ -n "${USE_STARTER_CONFIG:-}" ]; then
            # Starter content has real newlines from cat — use printf to avoid escape corruption
            printf '%s\n' "$CONFIG_SECTION" >> CLAUDE.md.tmp
          else
            # Auto-generated content uses \n literals — needs echo -e
            echo -e "$CONFIG_SECTION" >> CLAUDE.md.tmp
          fi
          # Version-stamp so `--update` can detect stale wizard output.
          printf '\n<!-- cck:wizard-schema=%s -->\n' "$WIZARD_SCHEMA_VERSION" >> CLAUDE.md.tmp
          # Re-attach any content after the target section.
          if [ -n "$END_LINE" ]; then
            printf '\n' >> CLAUDE.md.tmp
            tail -n +"$END_LINE" CLAUDE.md >> CLAUDE.md.tmp
          fi
          mv CLAUDE.md.tmp CLAUDE.md
          echo -e "  ${GREEN}[CONFIGURED]${RESET} CLAUDE.md §${SECTION_NUM} (Project-Specific Configuration)"
        else
          echo -e "  ${DIM}[SKIP]${RESET} CLAUDE.md §${SECTION_NUM} already customized"
        fi
      fi
    fi
  fi

  # Advanced: main session model override — replaces the default "opusplan".
  if [ -n "$CUSTOM_MODEL" ] && [ -f ".claude/settings.json" ] && command -v python3 &>/dev/null; then
    CCK_MODEL="$CUSTOM_MODEL" python3 -c "
import json, os
p = '.claude/settings.json'
with open(p) as f: s = json.load(f)
s['model'] = os.environ['CCK_MODEL']
with open(p, 'w') as f: json.dump(s, f, indent=2); f.write('\n')
" && echo -e "  ${GREEN}[CONFIGURED]${RESET} settings.json model → ${BOLD}${CUSTOM_MODEL}${RESET}"
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

echo -e "  ${BOLD}Your setup:${RESET}"
[ -n "$PROJECT_NAME" ]         && echo -e "    Project:       ${BOLD}$PROJECT_NAME${RESET}"
if [ -n "$STACK" ] && [ "$STACK" != "other" ]; then
  if [ -n "$NODE_FRAMEWORK" ]; then
    echo -e "    Stack:         ${BOLD}$STACK${RESET} ${DIM}($NODE_FRAMEWORK)${RESET}"
  elif [ -n "${PY_FRAMEWORK:-}" ]; then
    echo -e "    Stack:         ${BOLD}$STACK${RESET} ${DIM}($PY_FRAMEWORK)${RESET}"
  else
    echo -e "    Stack:         ${BOLD}$STACK${RESET}"
  fi
fi
[ -n "$PKG_MGR" ]              && echo -e "    Package mgr:   ${BOLD}$PKG_MGR${RESET}"
[ "$IS_MONOREPO" = true ]      && echo -e "    Monorepo:      ${BOLD}$MONOREPO_TOOL${RESET}"
[ "$HAS_CODEOWNERS" = true ]   && echo -e "    Ownership:     ${BOLD}CODEOWNERS detected${RESET}"
[ "$LARGE_CODEBASE" = true ]   && echo -e "    Codebase size: ${BOLD}${SOURCE_FILE_COUNT}+ source files${RESET}"
[ -n "$CMD_DEV" ]              && echo -e "    Dev command:   ${DIM}$CMD_DEV${RESET}"
[ -n "$CMD_TEST" ]             && echo -e "    Test command:  ${DIM}$CMD_TEST${RESET}"
[ -n "$CMD_LINT" ]             && echo -e "    Lint command:  ${DIM}$CMD_LINT${RESET}"
[ -n "$CMD_TYPECHECK" ]        && echo -e "    Typecheck:     ${DIM}$CMD_TYPECHECK${RESET}"
[ -n "$RESPONSE_STYLE" ]       && echo -e "    Response style:${BOLD} $RESPONSE_STYLE${RESET}"
SUMMARY_MODEL="${CUSTOM_MODEL:-opusplan}"
case "$SUMMARY_MODEL" in
  opusplan) SUMMARY_MODEL_NOTE="${DIM}(Opus in plan mode, Sonnet in execution)${RESET}" ;;
  sonnet)   SUMMARY_MODEL_NOTE="${DIM}(Sonnet 4.6 — balanced)${RESET}" ;;
  opus)     SUMMARY_MODEL_NOTE="${DIM}(Opus 4.6 — expensive)${RESET}" ;;
  haiku)    SUMMARY_MODEL_NOTE="${DIM}(Haiku 4.5 — cheapest)${RESET}" ;;
  *)        SUMMARY_MODEL_NOTE="" ;;
esac
echo -e "    Main model:    ${BOLD}${SUMMARY_MODEL}${RESET} ${SUMMARY_MODEL_NOTE}"

# Stack-aware concrete example to seed the first turn. Picks a plausible
# task tied to what we detected, instead of the generic "describe what you
# want to build".
TRY_EXAMPLE=""
case "$STACK" in
  node)
    case "$NODE_FRAMEWORK" in
      "Next.js")      TRY_EXAMPLE="add a /api/health route and a test" ;;
      "Remix")        TRY_EXAMPLE="add a /health loader and a Vitest test" ;;
      "SvelteKit")    TRY_EXAMPLE="add a /health +server.ts endpoint with a test" ;;
      "Astro")        TRY_EXAMPLE="add a /health API route and a test" ;;
      "Nuxt")         TRY_EXAMPLE="add a server/api/health.ts handler with a test" ;;
      "Vite + React") TRY_EXAMPLE="add a HealthStatus component with a Vitest test" ;;
      *)              TRY_EXAMPLE="add a typed utility with unit tests" ;;
    esac
    ;;
  python)
    case "${PY_FRAMEWORK:-}" in
      fastapi) TRY_EXAMPLE="add a /health endpoint and a pytest test" ;;
      django)  TRY_EXAMPLE="add a health view and a pytest-django test" ;;
      flask)   TRY_EXAMPLE="add a /health route and a pytest test" ;;
      llm)     TRY_EXAMPLE="wrap the LLM call with retries, tests, and an env-var key check" ;;
      *)       TRY_EXAMPLE="add a pytest fixture and a unit test" ;;
    esac
    ;;
  go)      TRY_EXAMPLE="add a /healthz handler and a table-driven test" ;;
  rust)    TRY_EXAMPLE="add a CLI subcommand with clap + an integration test" ;;
  deno)    TRY_EXAMPLE="add a Deno.serve handler and a Deno.test unit" ;;
  bun)     TRY_EXAMPLE="add a Bun.serve handler and a bun test" ;;
  elixir)  TRY_EXAMPLE="add a /health Phoenix controller and an ExUnit test" ;;
  ruby)    TRY_EXAMPLE="add a /health Rails controller and an RSpec test" ;;
  java|kotlin) TRY_EXAMPLE="add a /health controller and a JUnit test" ;;
  dotnet)  TRY_EXAMPLE="add a /health endpoint and an xUnit test" ;;
  php)     TRY_EXAMPLE="add a /health route and a PHPUnit test" ;;
  *)       TRY_EXAMPLE="review the current codebase structure and suggest next steps" ;;
esac

echo ""
echo -e "  ${BOLD}Get started:${RESET}"
echo -e "    1. Run 'claude' to start a session"
if [ -n "$TRY_EXAMPLE" ]; then
  echo -e "    2. Try: ${DIM}\"${TRY_EXAMPLE}\"${RESET}"
else
  echo -e "    2. Just describe what you want to build — skip /onboard on a fresh install"
fi
echo -e "    3. Use /fix, /feature, /refactor, /research for task playbooks"
echo -e "    4. Type /wrap-up when done to save session state"

if [ "$LARGE_CODEBASE" = true ]; then
  echo ""
  echo -e "  ${CYAN}${BOLD}Large codebase detected${RESET} ${DIM}(${SOURCE_FILE_COUNT}+ source files)${RESET}"
  echo -e "  Install SocratiCode MCP for semantic code search + dependency graphs:"
  echo -e "    ${DIM}claude plugin marketplace add giancarloerra/socraticode${RESET}"
  echo -e "    ${DIM}claude plugin install socraticode@socraticode${RESET}"
fi
echo ""
echo -e "  ${YELLOW}★${RESET} ${BOLD}If this saves you time, star the repo:${RESET}"
echo -e "    ${CYAN}https://github.com/codeverbojan/claude-code-kickstart${RESET}"
echo ""

# Cleanup temp dir (install.sh's trap doesn't fire after exec).
# Path validation: the prefix check alone is bypassable via "../" traversal
# (e.g. /tmp/../home/user). Resolve to an absolute canonical path first and
# re-check, then use `rm -rf --` to block leading-dash names and avoid
# following symlinks at the top level via the check-then-rm pattern.
cleanup_tmp_dir() {
  local raw="$1"
  [ -z "$raw" ] && return
  [ -d "$raw" ] || return
  local resolved
  if command -v realpath >/dev/null 2>&1; then
    resolved=$(realpath "$raw" 2>/dev/null) || return
  elif command -v python3 >/dev/null 2>&1; then
    resolved=$(python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$raw" 2>/dev/null) || return
  else
    # No resolver — bail rather than trust the raw path.
    return
  fi
  case "$resolved" in
    /tmp/*|/var/folders/*|/private/tmp/*|/private/var/folders/*)
      # Final guard: must still be a directory after resolution, and
      # not a symlink at the top level (realpath dereferenced it already,
      # so -h check catches the case where resolved points back to a link).
      [ -d "$resolved" ] && [ ! -L "$resolved" ] && rm -rf -- "$resolved"
      ;;
  esac
}
cleanup_tmp_dir "$TMP_DIR" || true
