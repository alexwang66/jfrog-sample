#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 5: QA sign-off + final PROD release.
#   - Attach a QA-approval evidence record (gate before PROD)
#   - Promote to PROD
#   - Call version-release to mark the version as RELEASED (immutable)
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

require jf
require jq

[[ -f "${PRIVATE_KEY}" ]] || die "Missing signing key at ${PRIVATE_KEY}. Run 00-init.sh first."

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
sed -e "s|REPLACE_WITH_APPROVER|${USER:-ci}|g" \
    -e "s|REPLACE_WITH_ISO_TIMESTAMP|${NOW}|g" \
    "${REPO_ROOT}/evidence/qa-approval.json" > "${TMP_DIR}/approval.json"
jq . "${TMP_DIR}/approval.json" >/dev/null

say "Attaching QA approval evidence"
jf evd create-evidence \
  --server-id "${JF_SERVER_ID}" \
  --application-key "${APP_KEY}" \
  --application-version "${APP_VERSION}" \
  --predicate "${TMP_DIR}/approval.json" \
  --predicate-type "https://jfrog.com/evidence/approval/v1" \
  --key "${PRIVATE_KEY}" \
  --key-alias "${KEY_ALIAS}"
ok "QA approval evidence attached"

# On platforms where PROD is a "release stage", version-promote is rejected with
# "promotion to release stage 'PROD' is not allowed, use release operation instead".
# In that case, version-release both promotes into PROD and marks the version as
# released in a single call — this is the correct final step.
say "Releasing ${APP_KEY}@${APP_VERSION} (promotes QA -> ${STAGE_PROD} and marks RELEASED)"
jf apptrust version-release "${APP_KEY}" "${APP_VERSION}" \
  --server-id "${JF_SERVER_ID}" \
  --sync
ok "Version released"

ok "Release lifecycle complete. Optionally run scripts/06-verify.sh to inspect."
