#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 7: Create a JFrog Unified Policy Service Template + Rule + Policy that
# BLOCKS promotion into DEV unless a security-scan/v1 evidence is attached to
# the application version.
#
# Model:
#   Template (Rego)  ── reusable policy code
#   Rule            ── template instance (optional parameters)
#   Policy          ── binds rule(s) to scope (application), stage gate, mode
#
# API base: /unifiedpolicy/api/v1
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

require jf
require jq
require curl

CFG_B64=$(jf config export "${JF_SERVER_ID}")
CFG=$(printf '%s' "$CFG_B64" | base64 -d)
BASE=$(printf '%s' "$CFG" | jq -r '.url' | sed 's:/$::')
TOKEN=$(printf '%s' "$CFG" | jq -r '.accessToken // empty')
[[ -n "$TOKEN" ]] || die "Server '${JF_SERVER_ID}' has no access token configured"

REGO_FILE="${REPO_ROOT}/policy/require-security-scan.rego"
[[ -f "${REGO_FILE}" ]] || die "Missing Rego at ${REGO_FILE}"
REGO_TEXT="$(cat "${REGO_FILE}")"

TEMPLATE_NAME="${TEMPLATE_NAME:-${APP_KEY}-require-security-scan}"
RULE_NAME="${RULE_NAME:-${APP_KEY}-require-security-scan-rule}"
POLICY_NAME="${POLICY_NAME:-${APP_KEY}-dev-entry-must-have-scan}"
POLICY_GATE="${POLICY_GATE:-entry}"
POLICY_STAGE="${POLICY_STAGE:-${STAGE_DEV}}"

say "Creating template '${TEMPLATE_NAME}'"
TMPL_BODY=$(jq -n --arg name "$TEMPLATE_NAME" --arg rego "$REGO_TEXT" '{
  name: $name,
  description: "AppTrust demo: require a security-scan/v1 evidence before promotion",
  category: "quality",
  data_source_type: "evidence",
  version: "1.0.0",
  parameters: [],
  scanners: [],
  is_custom: true,
  rego: $rego
}')
TMPL_ID=$(curl -sf -X POST \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$BASE/unifiedpolicy/api/v1/templates" -d "$TMPL_BODY" | jq -r '.id')
[[ -n "$TMPL_ID" && "$TMPL_ID" != "null" ]] || die "Template creation failed"
ok "Template id: $TMPL_ID"

say "Creating rule '${RULE_NAME}'"
RULE_BODY=$(jq -n --arg name "$RULE_NAME" --arg tid "$TMPL_ID" '{
  name: $name,
  description: "Require security-scan/v1 evidence for the target application",
  template_id: $tid,
  parameters: [],
  is_custom: true
}')
RULE_ID=$(curl -sf -X POST \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$BASE/unifiedpolicy/api/v1/rules" -d "$RULE_BODY" | jq -r '.id')
[[ -n "$RULE_ID" && "$RULE_ID" != "null" ]] || die "Rule creation failed"
ok "Rule id: $RULE_ID"

say "Creating policy '${POLICY_NAME}' (mode=block, gate=${POLICY_GATE}, stage=${POLICY_STAGE})"
POLICY_BODY=$(jq -n \
  --arg name "$POLICY_NAME" \
  --arg app "$APP_KEY" \
  --arg gate "$POLICY_GATE" \
  --arg stage "$POLICY_STAGE" \
  --arg rid "$RULE_ID" '{
  name: $name,
  description: "Block promotion into stage unless security-scan evidence exists",
  enabled: true,
  mode: "block",
  rule_ids: [$rid],
  scope: { type: "application", application_keys: [$app] },
  action: { type: "certify_to_gate", stage: { gate: $gate, key: $stage } }
}')
POLICY_ID=$(curl -sf -X POST \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  "$BASE/unifiedpolicy/api/v1/policies" -d "$POLICY_BODY" | jq -r '.id')
[[ -n "$POLICY_ID" && "$POLICY_ID" != "null" ]] || die "Policy creation failed"
ok "Policy id: $POLICY_ID"

cat <<EOF

Summary
-------
Template : ${TEMPLATE_NAME} (${TMPL_ID})
Rule     : ${RULE_NAME} (${RULE_ID})
Policy   : ${POLICY_NAME} (${POLICY_ID})
Blocks   : promotion into stage '${POLICY_STAGE}' (${POLICY_GATE}_gate) for app '${APP_KEY}'
           unless an evidence of predicateType 'https://jfrog.com/evidence/security-scan/v1' is attached.

To exercise:
  1. Create a NEW version with only build source (no security-scan evidence).
  2. Run 'jf apptrust version-promote ${APP_KEY} <version> ${POLICY_STAGE}' — expect
     "failed due to policy violations".
  3. Attach the evidence and retry — expect success.
EOF
