#!/usr/bin/env bash
set -euo pipefail

CHECK_ONLY=false
if [[ "${1:-}" == "--check-only" ]]; then
  CHECK_ONLY=true
fi

say() { printf '\033[1;36m> %s\033[0m\n' "$*"; }
ok() { printf '\033[1;32mOK %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33mWARN %s\033[0m\n' "$*"; }
die() { printf '\033[1;31mERROR %s\033[0m\n' "$*" >&2; exit 1; }

require() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "$1 found"
  else
    die "$1 is required"
  fi
}

install_jfrog_cli() {
  if command -v jf >/dev/null 2>&1; then
    ok "jf found: $(jf --version)"
    return
  fi

  say "Installing JFrog CLI"
  curl -fL https://install-cli.jfrog.io | sh
  command -v jf >/dev/null 2>&1 || die "jf installation failed"
  ok "jf installed: $(jf --version)"
}

say "Checking Codespace tools"
require git
require jq
require docker
install_jfrog_cli

if [[ "${CHECK_ONLY}" == "true" ]]; then
  warn "Skipping JFrog login because --check-only was used"
  exit 0
fi

[[ -n "${JF_URL:-}" ]] || die "JF_URL is required, for example: export JF_URL=https://demo.jfrogchina.com"
[[ -n "${JF_ACCESS_TOKEN:-}" ]] || die "JF_ACCESS_TOKEN is required"

JF_SERVER_ID="${JF_SERVER_ID:-demo}"

say "Configuring JFrog CLI server '${JF_SERVER_ID}'"
jf c add "${JF_SERVER_ID}" \
  --url "${JF_URL}" \
  --access-token "${JF_ACCESS_TOKEN}" \
  --interactive=false \
  --overwrite=true

say "Pinging AppTrust"
jf apptrust ping --server-id "${JF_SERVER_ID}"
ok "Codespace is ready for the AppTrust workshop"

