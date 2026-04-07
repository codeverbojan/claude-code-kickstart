#!/bin/bash
set -e

# Claude Code Kickstart — Bootstrap Installer
#
# This script downloads the template and launches the interactive wizard.
#
# Install:
#   bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh)
#
# Install + track distribution channel (useful for knowing which link drove the install):
#   CCK_SRC=twitter bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh)
#   # or as a flag:
#   bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh) --src=linkedin
#
# Update (preserves CLAUDE.md, primer.md, gotchas.md, settings.json, mcp.json):
#   bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh) --update
#
# Or clone and run:
#   git clone https://github.com/codeverbojan/claude-code-kickstart.git /tmp/cck && bash /tmp/cck/setup.sh

REPO="https://github.com/codeverbojan/claude-code-kickstart.git"
TMP_DIR=$(mktemp -d)

# ─── Install-source tracking ───
# Precedence: --src=X flag > CCK_SRC env var > "direct"
# The source is recorded to .claude/install-source.txt in the installed project
# so you can see which distribution channel drove each install.
INSTALL_SRC="${CCK_SRC:-direct}"
FILTERED_ARGS=()
for arg in "$@"; do
  case "$arg" in
    --src=*) INSTALL_SRC="${arg#--src=}" ;;
    *) FILTERED_ARGS+=("$arg") ;;
  esac
done
export CCK_SRC="$INSTALL_SRC"

trap 'rm -rf "$TMP_DIR"' EXIT

echo ""
echo -e "\033[1m  Claude Code Kickstart\033[0m"
echo -e "\033[2m  Production-grade agentic workflow for Claude Code\033[0m"
echo ""
echo "  Downloading template..."
git clone --quiet --depth 1 "$REPO" "$TMP_DIR" 2>/dev/null
echo -e "  \033[32mDone.\033[0m"
echo ""

# Hand off to the full setup script with access to TTY
exec bash "$TMP_DIR/setup.sh" "$TMP_DIR" "${FILTERED_ARGS[@]}"
