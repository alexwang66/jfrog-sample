#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# End-to-end driver for the AI-Catalog demo. Runs the "happy path" (no block).
# Use scripts/08-test-block.sh separately to demonstrate the policy blocking.
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/00-init.sh"
"${SCRIPT_DIR}/01-pull-model.sh"
"${SCRIPT_DIR}/02-upload-and-scan.sh"
"${SCRIPT_DIR}/03-create-version.sh"
"${SCRIPT_DIR}/04-attach-evidence.sh"
"${SCRIPT_DIR}/05-promote.sh"
"${SCRIPT_DIR}/06-approve-and-release.sh"
