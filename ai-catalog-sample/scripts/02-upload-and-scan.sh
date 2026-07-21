#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 2: Publish the pulled model into the DEV HF local repo with build-info
# so it can source an AppTrust application version. Then run an Xray scan.
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

require jf
require jq

[[ -d "${MODEL_DIR}" ]] || die "Model dir not found: ${MODEL_DIR}. Run 01-pull-model.sh first."

# HuggingFace repositories in Artifactory follow the layout:
#   <repo>/<org>/<model>/<revision>/<file>
# We upload every file the model shipped with under that path.
TARGET_PREFIX="${HF_REPO_DEV}/${MODEL_ORG}/${MODEL_NAME}/${MODEL_REVISION}"
say "Uploading model files to ${TARGET_PREFIX}"

# Build a file spec so upload happens in one build-info-tracked call.
SPEC=$(mktemp)
trap 'rm -f "${SPEC}"' EXIT

cat > "${SPEC}" <<JSON
{
  "files": [
    {
      "pattern": "${MODEL_DIR}/(*)",
      "target": "${TARGET_PREFIX}/{1}",
      "flat": "false",
      "recursive": "true",
      "exclusions": [
        "*.cache/*",
        "*.lock",
        "*.gitignore",
        "*.gitattributes"
      ]
    }
  ]
}
JSON

jf rt upload --spec "${SPEC}" \
  --server-id "${JF_SERVER_ID}" \
  --project "${JF_PROJECT}" \
  --build-name "${BUILD_NAME}" \
  --build-number "${BUILD_NUMBER}" \
  --threads 4 \
  --detailed-summary 2>&1 | tail -10

ok "Files uploaded"

say "Adding git metadata and publishing build-info"
jf rt build-add-git "${BUILD_NAME}" "${BUILD_NUMBER}" \
  --server-id "${JF_SERVER_ID}" \
  --project "${JF_PROJECT}" \
  "$(cd "${SCRIPT_DIR}/../.." && pwd)" 2>/dev/null \
  || warn "Skipping build-add-git (not a git repo)"

jf rt build-publish "${BUILD_NAME}" "${BUILD_NUMBER}" \
  --server-id "${JF_SERVER_ID}" \
  --project "${JF_PROJECT}" 2>&1 | tail -3
ok "Build-info published"

say "Running Xray build-scan (does not fail the pipeline)"
jf build-scan "${BUILD_NAME}" "${BUILD_NUMBER}" \
  --server-id "${JF_SERVER_ID}" \
  --project "${JF_PROJECT}" \
  --fail=false --vuln 2>&1 | tail -20
ok "Xray scan finished — see UI for details"

ok "Upload & scan complete. Next: scripts/03-create-version.sh"
