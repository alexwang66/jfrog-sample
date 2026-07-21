#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 7: Create a Unified Policy that BLOCKS promotion into PROD (release_gate)
# unless BOTH model-card/v1 and red-team/v1 evidence are attached.
#
# API base: /unifiedpolicy/api/v1  (Template -> Rule -> Policy)
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

require jf
require jq
require curl

CFG=$(jf config export "${JF_SERVER_ID}" | base64 -d)
BASE=$(printf '%s' "$CFG" | jq -r '.url' | sed 's:/$::')
TOKEN=$(printf '%s' "$CFG" | jq -r '.accessToken // empty')
[[ -n "$TOKEN" ]] || die "Server '${JF_SERVER_ID}' has no access token configured"

REGO_FILE="${REPO_ROOT}/policy/require-model-card-and-red-team.rego"
[[ -f "${REGO_FILE}" ]] || die "Missing Rego at ${REGO_FILE}"
REGO_TEXT="$(cat "${REGO_FILE}")"

TEMPLATE_NAME="${TEMPLATE_NAME:-${APP_KEY}-require-model-card-and-red-team}"
RULE_NAME="${RULE_NAME:-${APP_KEY}-require-model-card-and-red-team-rule}"
POLICY_NAME="${POLICY_NAME:-${APP_KEY}-prod-release-gate}"
# Block at the release gate — this is what version-release evaluates on the way to PROD.
POLICY_GATE="${POLICY_GATE:-release}"
POLICY_STAGE="${POLICY_STAGE:-${STAGE_PROD}}"

say "Creating template '${TEMPLATE_NAME}'"
TMPL_BODY=$(jq -n --arg name "$TEMPLATE_NAME" --arg rego "$REGO_TEXT" '{
  name: $name,
  description: "AI Catalog demo: require model-card + red-team evidence before PROD release",
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
  description: "Require model-card + red-team evidence on the ML application version",
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
  description: "Block PROD release unless model-card + red-team evidence attached",
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
Template : ${TEMPLATE_NAME}  (${TMPL_ID})
Rule     : ${RULE_NAME}      (${RULE_ID})
Policy   : ${POLICY_NAME}    (${POLICY_ID})
Blocks   : release into stage '${POLICY_STAGE}' (${POLICY_GATE}_gate) for app '${APP_KEY}'
           unless BOTH of these predicateTypes are attached:
             https://jfrog.com/evidence/model-card/v1
             https://jfrog.com/evidence/red-team/v1

Test the block with scripts/08-test-block.sh
EOF
