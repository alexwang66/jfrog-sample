#!/usr/bin/env bash
# ------------------------------------------------------------------------------
# Step 1: Pull the HuggingFace model THROUGH the JFrog HF remote proxy.
# The model files land in the remote's -cache repo. This proves the
# "AI Catalog" acts as a governed proxy — no direct pulls from huggingface.co.
# ------------------------------------------------------------------------------
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/config.sh"

require jf
require python3

# Point huggingface CLI at the Artifactory HF remote.
CFG=$(jf config export "${JF_SERVER_ID}" | base64 -d)
JF_URL=$(echo "$CFG" | jq -r '.url' | sed 's:/$::')
JF_TOKEN=$(echo "$CFG" | jq -r '.accessToken')
JF_USER=$(echo "$CFG" | jq -r '.user // "admin"')

export HF_ENDPOINT="${JF_URL}/artifactory/api/huggingfaceml/${HF_REMOTE}"
export HUGGING_FACE_HUB_TOKEN="${JF_TOKEN}"

say "Using AI-Catalog proxy as HF endpoint: ${HF_ENDPOINT}"
mkdir -p "${MODEL_DIR}"

# Always run huggingface_hub inside an isolated project venv — avoids pyenv
# shim mismatches and does not touch the user's global Python env.
VENV="${SCRIPT_DIR}/.venv"
if [[ ! -x "${VENV}/bin/python" ]]; then
  say "Creating project venv at ${VENV}"
  python3 -m venv "${VENV}"
fi
# shellcheck disable=SC1091
source "${VENV}/bin/activate"
if ! "${VENV}/bin/python" -m pip show huggingface_hub >/dev/null 2>&1; then
  say "Installing huggingface_hub into venv"
  "${VENV}/bin/pip" install --quiet --upgrade huggingface_hub
fi
ok "huggingface_hub ready"

# huggingface_hub 1.0+ renamed the CLI binary from 'huggingface-cli' to 'hf'.
HF_BIN="${VENV}/bin/hf"
[[ -x "$HF_BIN" ]] || HF_BIN="${VENV}/bin/huggingface-cli"
[[ -x "$HF_BIN" ]] || die "Neither hf nor huggingface-cli found in venv"

say "Downloading ${MODEL_FULL}@${MODEL_REVISION} via AI-Catalog (${HF_BIN##*/})"
"${HF_BIN}" download "${MODEL_FULL}" \
  --revision "${MODEL_REVISION}" \
  --local-dir "${MODEL_DIR}"
ok "Model saved to ${MODEL_DIR}"

ls -lh "${MODEL_DIR}" | tail -n +2

ok "Pull complete. Next: scripts/02-upload-and-scan.sh"
