#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 6: Deployment approval + PROD release.
#   - Attach a deployment-approval evidence record
#   - Call version-release (PROD is a release stage; promote is not allowed)
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

require jf
require jq

[[ -f "${PRIVATE_KEY}" ]] || die "Missing signing key. Run 00-init.sh first."

TMP=$(mktemp -d); trap 'rm -rf "${TMP}"' EXIT
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
sed -e "s|REPLACE_WITH_APPROVER|${USER:-ci}|g" \
    -e "s|REPLACE_WITH_ISO_TIMESTAMP|${NOW}|g" \
    "${REPO_ROOT}/evidence/deployment-approval.json" > "${TMP}/approval.json"

say "Attaching deployment approval evidence"
jf evd create-evidence \
  --server-id "${JF_SERVER_ID}" \
  --application-key "${APP_KEY}" \
  --application-version "${APP_VERSION}" \
  --predicate "${TMP}/approval.json" \
  --predicate-type "https://jfrog.com/evidence/approval/v1" \
  --key "${PRIVATE_KEY}" \
  --key-alias "${KEY_ALIAS}" 2>&1 | tail -3
ok "Approval evidence attached"

# PROD is a release stage — version-promote is rejected, use version-release.
# --include-repos scopes the release to the PROD HF repo, avoiding
# "Forbidden to copy/move ... from Release Bundles repository" on the internal
# app-versions storage. --promotion-type keep records a metadata-only event.
say "Releasing ${APP_KEY}@${APP_VERSION} (QA -> ${STAGE_PROD}, mark RELEASED)"
jf apptrust version-release "${APP_KEY}" "${APP_VERSION}" \
  --server-id "${JF_SERVER_ID}" \
  --promotion-type keep \
  --include-repos "${HF_REPO_PROD}" \
  --sync 2>&1 | tail -3
ok "Version released"

ok "Lifecycle complete. Optional: scripts/07-create-policy.sh + scripts/08-test-block.sh"
