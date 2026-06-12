#!/usr/bin/env bash
# Install the devsecops-helper plugin from Artifactory into ./demo-app
# for the Claude Code harness.
#
# Usage:
#   ./scripts/install.sh                 # install latest version
#   VERSION=1.0.0 ./scripts/install.sh   # install a specific version
set -euo pipefail

cd "$(dirname "$0")/.."

REPO="${REPO:-alex-agent-plugins-local}"
SERVER_ID="${SERVER_ID:-soleng}"
HARNESS="${HARNESS:-claude}"

EXTRA_ARGS=()
if [[ -n "${VERSION:-}" ]]; then
  EXTRA_ARGS+=(--version "$VERSION")
fi

jf agent plugins install devsecops-helper \
  --repo "$REPO" \
  --server-id "$SERVER_ID" \
  --harness "$HARNESS" \
  --project-dir ./demo-app \
  --quiet \
  "${EXTRA_ARGS[@]}"

echo
echo "Installed files:"
find demo-app/.claude/plugins -type f
