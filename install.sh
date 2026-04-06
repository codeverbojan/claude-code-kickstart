#!/bin/bash
set -e

# Claude Code Kickstart — Bootstrap Installer
#
# This script downloads the template and launches the interactive wizard.
#
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/codeverbojan/claude-code-kickstart/main/install.sh)
#
# Or clone and run:
#   git clone https://github.com/codeverbojan/claude-code-kickstart.git /tmp/cck && bash /tmp/cck/setup.sh

REPO="https://github.com/codeverbojan/claude-code-kickstart.git"
TMP_DIR=$(mktemp -d)

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
exec bash "$TMP_DIR/setup.sh" "$TMP_DIR" "$@"
