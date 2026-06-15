#!/usr/bin/env bash
# Publish the devsecops-helper plugin to the Agent Plugins repository.
#
# Usage:
#   ./scripts/publish.sh
set -euo pipefail

cd "$(dirname "$0")/.."

REPO="${REPO:-alex-agent-plugins-local}"
SERVER_ID="${SERVER_ID:-soleng}"
PLUGIN_DIR="./devsecops-helper"

jf agent plugins publish "$PLUGIN_DIR" \
  --repo "$REPO" \
  --server-id "$SERVER_ID" \
  --quiet
