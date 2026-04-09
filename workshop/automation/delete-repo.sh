#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_KIND="${1:-all}"

delete_repos() {
  local values_file="$1"

  for row in $(jq -r '.[] | @base64' "$values_file"); do
    _jq() {
      echo "$row" | base64 --decode | jq -r "$1"
    }

    jf rt repo-delete "$(_jq '.key')" --quiet
  done
}

case "$REPO_KIND" in
  all)
    delete_repos "$SCRIPT_DIR/virtual-repo-values.json"
    delete_repos "$SCRIPT_DIR/remote-repo-values.json"
    delete_repos "$SCRIPT_DIR/local-repo-values.json"
    ;;
  local)
    delete_repos "$SCRIPT_DIR/local-repo-values.json"
    ;;
  remote)
    delete_repos "$SCRIPT_DIR/remote-repo-values.json"
    ;;
  virtual)
    delete_repos "$SCRIPT_DIR/virtual-repo-values.json"
    ;;
  *)
    echo "Usage: $0 [all|local|remote|virtual]" >&2
    exit 1
    ;;
esac
