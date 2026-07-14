#!/usr/bin/env bash
# Build the crate, deploy it to an Artifactory Cargo repo via JFrog CLI, and verify.
set -euo pipefail
JF_SERVER_ID="${JF_SERVER_ID:-demo}"
REPO="${REPO:-alex-cargo-local}"
NAME="samplecode"
VERSION="$(grep -m1 '^version' Cargo.toml | sed -E 's/.*"(.*)".*/\1/')"

echo ">> packaging ${NAME} ${VERSION}"
cargo package --allow-dirty --no-verify

echo ">> deploying to ${REPO} on server '${JF_SERVER_ID}' (jf rt upload)"
jf rt upload "target/package/${NAME}-${VERSION}.crate" \
  "${REPO}/${NAME}/${VERSION}/${NAME}-${VERSION}.crate" \
  --target-props "cargo.name=${NAME};cargo.version=${VERSION}" \
  --server-id "${JF_SERVER_ID}"

echo ">> verifying via AQL"
jf rt curl -s -XPOST /api/search/aql -H "Content-Type: text/plain" \
  -d "items.find({\"repo\":\"${REPO}\",\"name\":\"${NAME}-${VERSION}.crate\"}).include(\"path\",\"name\")" \
  --server-id "${JF_SERVER_ID}" | jq '{found: .range.total, items: [.results[] | .path + "/" + .name]}'
