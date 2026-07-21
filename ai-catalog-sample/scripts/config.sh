#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Shared configuration for AI-Catalog demo scripts.
# Override any value by exporting it in your shell before sourcing.
# ------------------------------------------------------------------------------
set -euo pipefail

# --- JFrog CLI target (must have AppTrust enabled) ---------------------------
export JF_SERVER_ID="${JF_SERVER_ID:-demo}"
export JF_PROJECT="${JF_PROJECT:-alex}"

# --- Application identity ----------------------------------------------------
export APP_KEY="${APP_KEY:-alex-ml-classifier}"
export APP_VERSION="${APP_VERSION:-1.0.0}"

# --- Model to pull from HuggingFace ------------------------------------------
export MODEL_ORG="${MODEL_ORG:-distilbert}"
export MODEL_NAME="${MODEL_NAME:-distilbert-base-uncased}"
export MODEL_REVISION="${MODEL_REVISION:-main}"
export MODEL_FULL="${MODEL_ORG}/${MODEL_NAME}"

# --- Artifactory HuggingFace repositories ------------------------------------
# Remote repo proxies huggingface.co (already exists on demo).
export HF_REMOTE="${HF_REMOTE:-alex-huggingfaceml-remote}"
# Stage repos (created by 00-init.sh if missing).
export HF_REPO_DEV="${HF_REPO_DEV:-alex-huggingfaceml-dev-local}"
export HF_REPO_QA="${HF_REPO_QA:-alex-huggingfaceml-qa-local}"
export HF_REPO_PROD="${HF_REPO_PROD:-alex-huggingfaceml-prod-local}"

# --- Lifecycle stage names ---------------------------------------------------
export STAGE_DEV="${STAGE_DEV:-DEV}"
export STAGE_QA="${STAGE_QA:-QA}"
export STAGE_PROD="${STAGE_PROD:-PROD}"

# --- Build info --------------------------------------------------------------
export BUILD_NAME="${BUILD_NAME:-${APP_KEY}-build}"
export BUILD_NUMBER="${BUILD_NUMBER:-${APP_VERSION}}"
export BUILD_INFO_REPO="${BUILD_INFO_REPO:-${JF_PROJECT}-build-info}"

# --- Evidence signing --------------------------------------------------------
SCRIPT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export KEY_DIR="${KEY_DIR:-${SCRIPT_ROOT}/.keys}"
export KEY_ALIAS="${KEY_ALIAS:-${APP_KEY}-evidence-key}"
export PRIVATE_KEY="${PRIVATE_KEY:-${KEY_DIR}/evidence.key}"
export PUBLIC_KEY="${PUBLIC_KEY:-${KEY_DIR}/evidence.pub}"

# --- Registry hostname (derived) ---------------------------------------------
if [[ -z "${REGISTRY_HOST:-}" ]]; then
  REGISTRY_HOST="$(jf c show "${JF_SERVER_ID}" 2>/dev/null \
    | awk -F'https://' '/JFrog Platform URL:/ {print $2}' \
    | sed 's:/$::')"
  export REGISTRY_HOST
fi

# --- Working directory for downloaded model ----------------------------------
export MODEL_DIR="${MODEL_DIR:-${SCRIPT_ROOT}/.model-cache/${MODEL_NAME}}"

# --- Pretty printing ---------------------------------------------------------
say() { printf '\033[1;36m▶ %s\033[0m\n' "$*"; }
ok()  { printf '\033[1;32m✓ %s\033[0m\n' "$*"; }
warn(){ printf '\033[1;33m! %s\033[0m\n' "$*"; }
die() { printf '\033[1;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }
require() { command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"; }
