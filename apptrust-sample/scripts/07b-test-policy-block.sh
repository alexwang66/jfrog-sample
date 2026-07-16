#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 7b: Prove the policy blocks a promotion. Creates a NEW version
# (${TEST_VERSION:-1.1.0}) from the current build WITHOUT attaching the
# required security-scan evidence, attempts to promote it, expects failure,
# then attaches the evidence and promotes successfully.
#
# Pre-requisite: 07-create-policy.sh has been run.
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

require jf
require jq

TEST_VERSION="${TEST_VERSION:-1.1.0}"
BUILD_INFO_REPO="${BUILD_INFO_REPO:-${JF_PROJECT}-build-info}"

say "Creating version ${APP_KEY}@${TEST_VERSION} (no evidence attached)"
jf apptrust version-create "${APP_KEY}" "${TEST_VERSION}" \
  --server-id "${JF_SERVER_ID}" \
  --source-type-builds "name=${BUILD_NAME}, id=${TEST_VERSION}, repo-key=${BUILD_INFO_REPO}" \
  --tag "policy-test-${TEST_VERSION}" \
  --sync

say "Attempting promotion to ${STAGE_DEV} — expected: BLOCKED"
if jf apptrust version-promote "${APP_KEY}" "${TEST_VERSION}" "${STAGE_DEV}" \
     --server-id "${JF_SERVER_ID}" --promotion-type copy --sync 2>&1 | tee /tmp/promote-$$.out; then
  die "Promotion should have been blocked but was not!"
else
  if grep -q "policy violations" /tmp/promote-$$.out; then
    ok "Promotion correctly blocked by policy"
  else
    warn "Promotion failed for a different reason (see /tmp/promote-$$.out)"
    exit 1
  fi
fi

say "Attaching security-scan evidence to unblock"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
sed -e "s|REPLACE_WITH_TAG|${TEST_VERSION}|g" \
    -e "s|REPLACE_WITH_PLATFORM|${REGISTRY_HOST}|g" \
    -e "s|REPLACE_WITH_REPO|${DOCKER_REPO_DEV}|g" \
    "${REPO_ROOT}/evidence/security-scan.json" > "${TMP}/scan.json"

jf evd create-evidence \
  --server-id "${JF_SERVER_ID}" \
  --application-key "${APP_KEY}" \
  --application-version "${TEST_VERSION}" \
  --predicate "${TMP}/scan.json" \
  --predicate-type "https://jfrog.com/evidence/security-scan/v1" \
  --key "${PRIVATE_KEY}" \
  --key-alias "${KEY_ALIAS}"

say "Retrying promotion — expected: SUCCESS"
jf apptrust version-promote "${APP_KEY}" "${TEST_VERSION}" "${STAGE_DEV}" \
  --server-id "${JF_SERVER_ID}" --promotion-type copy --sync
ok "Promotion succeeded after evidence attached"
