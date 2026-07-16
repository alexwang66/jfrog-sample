#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Cleanup: delete the application version and (optionally) the application.
# Evidence records on the version are removed with the version itself.
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

require jf

say "Deleting application version ${APP_KEY}@${APP_VERSION}"
jf apptrust version-delete "${APP_KEY}" "${APP_VERSION}" \
  --server-id "${JF_SERVER_ID}" \
  --quiet 2>/dev/null \
  || warn "Version delete failed or version not found"

if [[ "${DELETE_APPLICATION:-false}" == "true" ]]; then
  say "Deleting application ${APP_KEY}"
  jf apptrust app-delete "${APP_KEY}" \
    --server-id "${JF_SERVER_ID}" \
    --quiet 2>/dev/null \
    || warn "Application delete failed"
fi

ok "Cleanup complete"
