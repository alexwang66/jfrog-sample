#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 3: Create the AppTrust application version, sourcing it from the
# published build-info. Version starts as PRE_RELEASE (no stage yet).
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
require jf

say "Creating application version ${APP_KEY}@${APP_VERSION}"
jf apptrust version-create "${APP_KEY}" "${APP_VERSION}" \
  --server-id "${JF_SERVER_ID}" \
  --source-type-builds "name=${BUILD_NAME}, id=${BUILD_NUMBER}, repo-key=${BUILD_INFO_REPO}" \
  --tag "ai-catalog-${APP_VERSION}" \
  --sync 2>&1 | tail -5
ok "Version created (PRE_RELEASE)"

ok "Next: scripts/04-attach-evidence.sh"
