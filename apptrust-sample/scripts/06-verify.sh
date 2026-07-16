#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 6 (optional): Verify all evidence attached to the application version
# using the ECDSA public key. Uses the OneModel GraphQL API to list the
# promotion history so you can confirm each stage transition.
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

require jf
require jq
require curl

say "Verifying evidence signatures for ${APP_KEY}@${APP_VERSION}"
jf evd verify-evidence \
  --server-id "${JF_SERVER_ID}" \
  --project "${JF_PROJECT}" \
  --application-key "${APP_KEY}" \
  --application-version "${APP_VERSION}" \
  --use-artifactory-keys \
  || warn "Signature verification returned a non-zero status. Inspect output above."

say "Fetching promotion history via OneModel GraphQL"
TOKEN="$(jf c export "${JF_SERVER_ID}" | base64 -d | jq -r '.accessToken // empty')"
URL="$(jf c export "${JF_SERVER_ID}" | base64 -d | jq -r '.url' | sed 's:/$::')"
[[ -n "${TOKEN}" ]] || die "Server '${JF_SERVER_ID}' has no access token configured"

QUERY=$(cat <<GQL
{
  applications {
    getApplicationVersion(applicationKey: "${APP_KEY}", version: "${APP_VERSION}") {
      version
      status
      releaseStatus
      currentStageName
      promotions(first: 20) {
        edges {
          node {
            sourceStageName
            targetStageName
            status
            createdBy
            createdAt
          }
        }
      }
    }
  }
}
GQL
)

RESP="/tmp/apptrust-verify-$$.json"
curl -s -X POST "${URL}/onemodel/api/v1/graphql" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg q "${QUERY}" '{query: $q}')" \
  -o "${RESP}"

jq . "${RESP}"
ok "Verification report saved to ${RESP}"
