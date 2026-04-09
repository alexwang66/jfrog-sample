#!/bin/sh

set -eu

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPO_KIND="${1:-all}"

build_vars_lines() {
  python3 - "$1" <<'PY'
import json
import sys

with open(sys.argv[1], "r", encoding="utf-8") as f:
    data = json.load(f)

for item in data:
    repo_type = item.get("rclass", "")
    xray_enable = str(item.get("xrayIndex", "false")).lower()
    parts = [
        f"repo-name={item.get('key', '')}",
        f"package-type={item.get('packageType', '')}",
        f"repo-type={repo_type}",
        f"repo-layout={item.get('repoLayoutRef', '')}",
        f"xray-enable={xray_enable}",
    ]

    if repo_type == "remote":
        parts.append(f"repo-url={item.get('url', '')}")
    elif repo_type == "virtual":
        parts.append(f"deploy-repo-name={item.get('defaultDeploymentRepo', '')}")
        parts.append(f"external-remote-repo-name={item.get('externalDependenciesRemoteRepo', '')}")
        parts.append(f"repos={item.get('repositories', '')}")

    print(";".join(parts))
PY
}

create_repos() {
  template_file="$1"
  values_file="$2"

  build_vars_lines "$values_file" | while IFS= read -r vars_string; do
    [ -n "$vars_string" ] || continue
    jf rt repo-create "$template_file" --vars "$vars_string"
  done
}

case "$REPO_KIND" in
  all)
    create_repos "$SCRIPT_DIR/local-repo-template.json" "$SCRIPT_DIR/local-repo-values.json"
    create_repos "$SCRIPT_DIR/remote-repo-template.json" "$SCRIPT_DIR/remote-repo-values.json"
    create_repos "$SCRIPT_DIR/virtual-repo-template.json" "$SCRIPT_DIR/virtual-repo-values.json"
    ;;
  local)
    create_repos "$SCRIPT_DIR/local-repo-template.json" "$SCRIPT_DIR/local-repo-values.json"
    ;;
  remote)
    create_repos "$SCRIPT_DIR/remote-repo-template.json" "$SCRIPT_DIR/remote-repo-values.json"
    ;;
  virtual)
    create_repos "$SCRIPT_DIR/virtual-repo-template.json" "$SCRIPT_DIR/virtual-repo-values.json"
    ;;
  *)
    echo "Usage: $0 [all|local|remote|virtual]" >&2
    exit 1
    ;;
esac
