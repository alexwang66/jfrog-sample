#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSHOP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${WORKSHOP_DIR}/../.." && pwd)"
APPTRUST_DIR="${REPO_ROOT}/apptrust-sample"

die() { printf '\033[1;31mERROR %s\033[0m\n' "$*" >&2; exit 1; }
say() { printf '\033[1;36m> %s\033[0m\n' "$*"; }

[[ -d "${APPTRUST_DIR}" ]] || die "apptrust-sample not found at ${APPTRUST_DIR}"
[[ -n "${JF_URL:-}" ]] || die "JF_URL is required, for example: export JF_URL=https://demo.jfrogchina.com"
[[ -n "${JF_ACCESS_TOKEN:-}" ]] || die "JF_ACCESS_TOKEN is required"

export JF_SERVER_ID="${JF_SERVER_ID:-demo}"
export JF_PROJECT="${JF_PROJECT:-alex}"
export APP_KEY="${APP_KEY:-alex-codespace-apptrust}"
export APP_NAME="${APP_NAME:-Alex Codespace AppTrust}"
export APP_VERSION="${APP_VERSION:-1.0.$(date +%s)}"
export IMAGE_NAME="${IMAGE_NAME:-${APP_KEY}}"
export IMAGE_TAG="${IMAGE_TAG:-${APP_VERSION}}"
export BUILD_NAME="${BUILD_NAME:-${APP_KEY}-build}"
export BUILD_NUMBER="${BUILD_NUMBER:-${APP_VERSION}}"
export DOCKER_REPO_DEV="${DOCKER_REPO_DEV:-alex-docker-dev-local}"
export DOCKER_REPO_QA="${DOCKER_REPO_QA:-alex-docker-qa-local}"
export DOCKER_REPO_PROD="${DOCKER_REPO_PROD:-alex-docker-prod-local}"
export STAGE_DEV="${STAGE_DEV:-DEV}"
export STAGE_QA="${STAGE_QA:-QA}"
export STAGE_PROD="${STAGE_PROD:-PROD}"
export KEY_DIR="${KEY_DIR:-${WORKSHOP_DIR}/.keys/${APP_KEY}-${APP_VERSION}}"
export KEY_ALIAS="${KEY_ALIAS:-${APP_KEY}-evidence-key-${APP_VERSION}}"

say "AppTrust workshop configuration"
cat <<EOF
JF_SERVER_ID=${JF_SERVER_ID}
JF_PROJECT=${JF_PROJECT}
APP_KEY=${APP_KEY}
APP_VERSION=${APP_VERSION}
IMAGE_NAME=${IMAGE_NAME}
DOCKER_REPO_DEV=${DOCKER_REPO_DEV}
STAGES=${STAGE_DEV} -> ${STAGE_QA} -> ${STAGE_PROD}/release
EOF

say "Ensuring JFrog CLI is configured"
"${SCRIPT_DIR}/bootstrap-codespace.sh"

say "Running AppTrust lifecycle from ${APPTRUST_DIR}"
(
  cd "${APPTRUST_DIR}"
  ./scripts/00-init.sh
  ./scripts/01-build.sh
  ./scripts/02-create-version.sh
  ./scripts/03-attach-evidence.sh
  ./scripts/04-promote.sh
  ./scripts/05-approve-and-release.sh
  ./scripts/06-verify.sh
)

say "Completed AppTrust release: ${APP_KEY}@${APP_VERSION}"

