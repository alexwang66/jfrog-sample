#!/usr/bin/env bash
# Install the devsecops-helper plugin into Claude Code via a local-filesystem
# marketplace.
#
# Why local-fs and not the Artifactory claude-marketplace.json directly:
# as of Claude Code 2.1.174, Claude's "url" plugin source means a GIT repo
# (it runs `git clone`), but JFrog publishes "source":"url" pointing to a ZIP.
# So `claude plugin install` against the Artifactory marketplace fails. A local
# marketplace (source: ./devsecops-helper) installs natively. See README step 4.
#
# Usage:
#   ./scripts/install-claude-plugin.sh
set -euo pipefail

# Repo root (this script lives in scripts/)
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MARKETPLACE="alex-agent-plugins-local-fs"
PLUGIN="devsecops-helper"

# 0. Ensure the Claude Code CLI is available.
if ! command -v claude >/dev/null 2>&1; then
  echo "==> claude CLI not found; installing to ~/.local/bin ..."
  curl -fsSL https://claude.ai/install.sh | bash
  export PATH="$HOME/.local/bin:$PATH"
  hash -r
fi
echo "==> claude $(claude --version)"

# 1. Register this repo as a local marketplace (idempotent: update if present).
if claude plugin marketplace list 2>/dev/null | grep -q "$MARKETPLACE"; then
  echo "==> Marketplace '$MARKETPLACE' already registered; updating ..."
  claude plugin marketplace update "$MARKETPLACE"
else
  echo "==> Registering local marketplace at $ROOT ..."
  claude plugin marketplace add "$ROOT"
fi

# 2. Install (or reinstall) the plugin.
if claude plugin list 2>/dev/null | grep -q "${PLUGIN}@${MARKETPLACE}"; then
  echo "==> Plugin already installed; reinstalling to pick up changes ..."
  claude plugin uninstall "$PLUGIN" || true
fi
claude plugin install "${PLUGIN}@${MARKETPLACE}"

# 3. Report.
echo
echo "==> Installed:"
claude plugin list | grep -A2 -i "$PLUGIN" || true
echo
echo "Restart Claude Code to load the plugin. It then provides:"
echo "  /scan-deps      slash command"
echo "  release-notes   skill"
