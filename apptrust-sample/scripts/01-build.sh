#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 1: Build the Docker image, push to the DEV repo with build-info, and
# publish build-info to Artifactory so the AppTrust version can source from it.
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

require docker
require jf

[[ -n "${REGISTRY_HOST}" ]] || die "REGISTRY_HOST could not be resolved from jf config"

IMAGE_REF="${REGISTRY_HOST}/${DOCKER_REPO_DEV}/${IMAGE_NAME}:${IMAGE_TAG}"

say "Building Docker image ${IMAGE_REF}"
docker build \
  --platform linux/amd64 \
  --label "org.opencontainers.image.title=${IMAGE_NAME}" \
  --label "org.opencontainers.image.version=${APP_VERSION}" \
  --label "org.opencontainers.image.source=https://github.com/jfrog/apptrust-sample" \
  -t "${IMAGE_REF}" \
  "${REPO_ROOT}"
ok "Image built"

say "Pushing image with build-info tracking"
jf docker push "${IMAGE_REF}" \
  --server-id "${JF_SERVER_ID}" \
  --project "${JF_PROJECT}" \
  --build-name "${BUILD_NAME}" \
  --build-number "${BUILD_NUMBER}"
ok "Image pushed to ${DOCKER_REPO_DEV}"

say "Collecting VCS metadata for build-info"
jf rt build-add-git "${BUILD_NAME}" "${BUILD_NUMBER}" \
  --server-id "${JF_SERVER_ID}" \
  --project "${JF_PROJECT}" \
  "${REPO_ROOT}" 2>/dev/null \
  || warn "Skipping build-add-git (not a git repo or git metadata unavailable)"

say "Publishing build-info ${BUILD_NAME}/${BUILD_NUMBER}"
jf rt build-publish "${BUILD_NAME}" "${BUILD_NUMBER}" \
  --server-id "${JF_SERVER_ID}" \
  --project "${JF_PROJECT}"
ok "Build info published"

ok "Build complete. Next: scripts/02-create-version.sh"
