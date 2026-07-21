#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 5: Promote the model version through DEV -> QA. Each hop is evaluated
# against the Unified Policy attached to the corresponding gate.
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
require jf

# For HuggingFace models, promotion between stages uses --promotion-type keep:
# the model files stay in the DEV repo and each promotion is recorded as a
# metadata event only. This avoids expensive multi-GB copies (a standard ML
# MLOps pattern) and works around the "Forbidden to copy/move ... from Release
# Bundles repository" restriction on the internal application-versions storage.
for stage in "${STAGE_DEV}" "${STAGE_QA}"; do
  say "Promoting ${APP_KEY}@${APP_VERSION} to ${stage} (keep)"
  if jf apptrust version-promote "${APP_KEY}" "${APP_VERSION}" "${stage}" \
       --server-id "${JF_SERVER_ID}" \
       --promotion-type keep \
       --sync 2>/tmp/promote-$$.log; then
    ok "Promoted to ${stage}"
  else
    if grep -qi "same as current stage" /tmp/promote-$$.log; then
      warn "Already at ${stage}, skipping"
    else
      cat /tmp/promote-$$.log
      die "Promotion to ${stage} failed"
    fi
  fi
done

ok "Reached ${STAGE_QA}. Next: scripts/06-approve-and-release.sh"
