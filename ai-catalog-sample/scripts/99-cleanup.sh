#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Cleanup: delete demo versions + optionally the application and the policy.
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

require jf

for v in "${APP_VERSION}" "1.0.1-blocktest"; do
  say "Deleting ${APP_KEY}@${v}"
  jf apptrust version-delete "${APP_KEY}" "${v}" \
    --server-id "${JF_SERVER_ID}" --quiet 2>/dev/null \
    || warn "Version ${v} not found or already gone"
done

if [[ "${DELETE_APPLICATION:-false}" == "true" ]]; then
  say "Deleting application ${APP_KEY}"
  jf apptrust app-delete "${APP_KEY}" \
    --server-id "${JF_SERVER_ID}" --quiet 2>/dev/null \
    || warn "app-delete failed"
fi

ok "Cleanup done. Note: HF repos and Unified Policies are NOT deleted automatically."
