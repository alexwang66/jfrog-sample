#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 2: Create the AppTrust application version, sourcing it from the
# published build-info. The version starts in PRE_RELEASE with no stage.
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

require jf

say "Creating application version ${APP_KEY}@${APP_VERSION}"
# If the build was published under a JFrog Project, its build-info lives in the
# project-specific build-info repo (e.g. "<project>-build-info"), NOT in the
# global "artifactory-build-info". Pass repo-key so version-create can find it.
BUILD_INFO_REPO="${BUILD_INFO_REPO:-${JF_PROJECT}-build-info}"

jf apptrust version-create "${APP_KEY}" "${APP_VERSION}" \
  --server-id "${JF_SERVER_ID}" \
  --source-type-builds "name=${BUILD_NAME}, id=${BUILD_NUMBER}, repo-key=${BUILD_INFO_REPO}" \
  --tag "sample-${APP_VERSION}" \
  --sync
ok "Version ${APP_KEY}@${APP_VERSION} created (PRE_RELEASE)"

ok "Version created. Next: scripts/03-attach-evidence.sh"
