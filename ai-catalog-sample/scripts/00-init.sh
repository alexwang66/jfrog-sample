#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 0: Bootstrap AI-Catalog demo prerequisites.
#   - Verify AppTrust reachable
#   - Ensure HF stage repos exist (dev/qa/prod)
#   - Ensure the AppTrust application exists (alex-ml-classifier)
#   - Generate an ECDSA signing key pair for evidence
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
require jf
require jq

say "Pinging AppTrust on server '${JF_SERVER_ID}'"
jf apptrust ping --server-id "${JF_SERVER_ID}"
ok "AppTrust reachable"

# Access token for direct REST calls (repo + app existence).
CFG=$(jf config export "${JF_SERVER_ID}" | base64 -d)
JF_URL=$(echo "$CFG" | jq -r '.url' | sed 's:/$::')
JF_TOKEN=$(echo "$CFG" | jq -r '.accessToken')

ensure_repo() {
  local key="$1" env="$2"
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer ${JF_TOKEN}" \
    "${JF_URL}/artifactory/api/repositories/${key}")
  if [[ "${code}" == "200" ]]; then
    ok "Repo ${key} already exists"
    return
  fi
  say "Creating HF local repo ${key} (env=${env})"
  curl -s -X PUT -H "Authorization: Bearer ${JF_TOKEN}" \
    -H "Content-Type: application/json" \
    "${JF_URL}/artifactory/api/repositories/${key}" \
    -d "{
      \"key\": \"${key}\",
      \"rclass\": \"local\",
      \"packageType\": \"huggingfaceml\",
      \"projectKey\": \"${JF_PROJECT}\",
      \"environments\": [\"${env}\"]
    }"
  echo
  ok "Repo ${key} created"
}
ensure_repo "${HF_REPO_DEV}"  "${STAGE_DEV}"
ensure_repo "${HF_REPO_QA}"   "${STAGE_QA}"
ensure_repo "${HF_REPO_PROD}" "${STAGE_PROD}"

say "Ensuring application ${APP_KEY} exists in project ${JF_PROJECT}"
if jf apptrust app-create "${APP_KEY}" \
      --server-id "${JF_SERVER_ID}" \
      --application-name "Alex ML Classifier" \
      --project "${JF_PROJECT}" \
      --business-criticality high \
      --maturity-level experimental \
      --desc "AI Catalog demo: HuggingFace model with evidence-gated lifecycle promotion" \
      --labels "team=ml;sample=ai-catalog;framework=transformers" 2>&1 | tee /tmp/appcreate-$$.log; then
  ok "Application ready"
else
  if grep -qiE "already exists|409" /tmp/appcreate-$$.log; then
    warn "Application ${APP_KEY} already exists — reusing"
  else
    die "app-create failed (see /tmp/appcreate-$$.log)"
  fi
fi

say "Generating ECDSA signing key pair"
mkdir -p "${KEY_DIR}"
if [[ ! -f "${PRIVATE_KEY}" || ! -f "${PUBLIC_KEY}" ]]; then
  jf evd generate-key-pair \
    --server-id "${JF_SERVER_ID}" \
    --key-file-path "${KEY_DIR}" \
    --key-alias "${KEY_ALIAS}" \
    --upload-public-key
  ok "Key pair generated and public key uploaded as '${KEY_ALIAS}'"
else
  ok "Key pair already present"
fi

ok "Init complete. Next: scripts/01-pull-model.sh"
