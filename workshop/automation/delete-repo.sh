#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_KIND="${1:-all}"

build_key_lines() {
  python3 - "$1" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

for item in data:
    print(item.get("key", ""))
PY
}

delete_repos() {
  values_file="$1"

  build_key_lines "$values_file" | while IFS= read -r repo_key; do
    [ -n "$repo_key" ] || continue
    jf rt repo-delete "$repo_key" --quiet
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
