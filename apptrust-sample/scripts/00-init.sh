#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 0: Bootstrap AppTrust demo prerequisites.
#   - Ping the AppTrust service to confirm auth works
#   - Create the JFrog application
#   - Generate and upload an evidence signing key pair (if missing)
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

require jf

say "Pinging AppTrust on server '${JF_SERVER_ID}'"
jf apptrust ping --server-id "${JF_SERVER_ID}"
ok "AppTrust reachable"

say "Ensuring signing key pair exists at ${KEY_DIR}"
mkdir -p "${KEY_DIR}"
if [[ ! -f "${PRIVATE_KEY}" || ! -f "${PUBLIC_KEY}" ]]; then
  jf evd generate-key-pair \
    --server-id "${JF_SERVER_ID}" \
    --key-file-path "${KEY_DIR}" \
    --key-alias "${KEY_ALIAS}" \
    --upload-public-key
  ok "Generated ECDSA key pair and uploaded public key as '${KEY_ALIAS}'"
else
  ok "Key pair already present, skipping generation"
fi

say "Creating application '${APP_KEY}' in project '${JF_PROJECT}'"
if jf apptrust app-create "${APP_KEY}" \
      --server-id "${JF_SERVER_ID}" \
      --application-name "${APP_NAME}" \
      --project "${JF_PROJECT}" \
      --business-criticality medium \
      --maturity-level experimental \
      --desc "AppTrust sample: full evidence + promotion lifecycle demo" \
      --labels "team=solutions;sample=apptrust" 2>&1 | tee /tmp/appcreate-$$.log; then
  ok "Application ready"
else
  if grep -qiE "already exists|409" /tmp/appcreate-$$.log; then
    warn "Application '${APP_KEY}' already exists — reusing it"
  else
    die "Failed to create application (see /tmp/appcreate-$$.log)"
  fi
fi

ok "Init complete. Next: scripts/01-build.sh"
