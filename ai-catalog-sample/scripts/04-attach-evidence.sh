#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 4: Attach ML-specific evidence to the application version.
#   1. Model Card verified (governance, license, intended-use)
#   2. Xray ML scan result (pickle exploits, malicious code, CVE)
#   3. Red-team assessment (OWASP LLM Top-10 + MITRE ATLAS)
# Each record is signed with the ECDSA key from 00-init.sh.
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
EVD_DIR="${REPO_ROOT}/evidence"

require jf
require jq

[[ -f "${PRIVATE_KEY}" ]] || die "Missing signing key. Run 00-init.sh first."

TMP=$(mktemp -d); trap 'rm -rf "${TMP}"' EXIT
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
RUN_ID="local-${NOW}"

render() {
  local src="$1" dst="$2"
  sed -e "s|REPLACE_WITH_MODEL_NAME|${MODEL_NAME}|g" \
      -e "s|REPLACE_WITH_MODEL_FULL|${MODEL_FULL}|g" \
      -e "s|REPLACE_WITH_REVISION|${MODEL_REVISION}|g" \
      -e "s|REPLACE_WITH_APPROVER|${USER:-ci}|g" \
      -e "s|REPLACE_WITH_ISO_TIMESTAMP|${NOW}|g" \
      -e "s|REPLACE_WITH_RUN_ID|${RUN_ID}|g" \
      -e "s|REPLACE_WITH_REPO|${HF_REPO_DEV}|g" \
      -e "s|REPLACE_WITH_PLATFORM|${REGISTRY_HOST}|g" \
      "${src}" > "${dst}"
  jq . "${dst}" >/dev/null || die "Invalid JSON: ${dst}"
}

render "${EVD_DIR}/model-card.json"      "${TMP}/model-card.json"
render "${EVD_DIR}/xray-model-scan.json" "${TMP}/xray-model-scan.json"
render "${EVD_DIR}/red-team.json"        "${TMP}/red-team.json"

attach() {
  local predicate="$1" ptype="$2" label="$3"
  say "Attaching ${label}"
  # NOTE: --project is auto-inferred from the application; passing it explicitly is rejected.
  jf evd create-evidence \
    --server-id "${JF_SERVER_ID}" \
    --application-key "${APP_KEY}" \
    --application-version "${APP_VERSION}" \
    --predicate "${predicate}" \
    --predicate-type "${ptype}" \
    --key "${PRIVATE_KEY}" \
    --key-alias "${KEY_ALIAS}" 2>&1 | tail -3
}

attach "${TMP}/model-card.json"      "https://jfrog.com/evidence/model-card/v1"       "Model Card (governance review)"
attach "${TMP}/xray-model-scan.json" "https://jfrog.com/evidence/ml-security-scan/v1" "Xray ML security scan"
attach "${TMP}/red-team.json"        "https://jfrog.com/evidence/red-team/v1"         "Red-team assessment"

ok "All pre-promotion evidence attached. Next: scripts/05-promote.sh"
