#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 4: Promote the application version through DEV -> QA. This copies the
# artifacts into the QA repository and creates a promotion record that becomes
# queryable via the OneModel GraphQL API.
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

require jf

say "Promoting ${APP_KEY}@${APP_VERSION} to stage '${STAGE_DEV}'"
jf apptrust version-promote "${APP_KEY}" "${APP_VERSION}" "${STAGE_DEV}" \
  --server-id "${JF_SERVER_ID}" \
  --promotion-type copy \
  --sync
ok "Promoted to ${STAGE_DEV}"

say "Promoting ${APP_KEY}@${APP_VERSION} to stage '${STAGE_QA}'"
jf apptrust version-promote "${APP_KEY}" "${APP_VERSION}" "${STAGE_QA}" \
  --server-id "${JF_SERVER_ID}" \
  --promotion-type copy \
  --sync
ok "Promoted to ${STAGE_QA}"

ok "Promoted through ${STAGE_DEV} -> ${STAGE_QA}. Next: scripts/05-approve-and-release.sh"
