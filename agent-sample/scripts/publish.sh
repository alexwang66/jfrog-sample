#!/usr/bin/env bash
# Publish the devsecops-helper plugin to the Agent Plugins repository.
#
# Usage:
#   ./scripts/publish.sh                # publish unsigned
#   SIGN=1 ./scripts/publish.sh         # publish with evidence signing
set -euo pipefail

cd "$(dirname "$0")/.."

REPO="${REPO:-alex-agent-plugins-local}"
SERVER_ID="${SERVER_ID:-soleng}"
PLUGIN_DIR="./devsecops-helper"

if [[ "${SIGN:-0}" == "1" ]]; then
  jf agent plugins publish "$PLUGIN_DIR" \
    --repo "$REPO" \
    --server-id "$SERVER_ID" \
    --signing-key keys/evidence-private.pem \
    --key-alias alex-demo-evidence-key \
    --quiet
else
  jf agent plugins publish "$PLUGIN_DIR" \
    --repo "$REPO" \
    --server-id "$SERVER_ID" \
    --quiet
fi
