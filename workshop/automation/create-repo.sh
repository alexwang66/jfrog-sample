#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_KIND="${1:-all}"

create_repos() {
  local template_file="$1"
  local values_file="$2"

  for row in $(jq -r '.[] | @base64' "$values_file"); do
    _jq() {
      echo "$row" | base64 --decode | jq -r "$1"
    }

    local repo_type
    repo_type="$(_jq '.rclass')"
    local xray_enable
    xray_enable="$(_jq '.xrayIndex // "false"')"
    local vars_string
    vars_string="repo-name=$(_jq '.key');package-type=$(_jq '.packageType');repo-type=${repo_type};repo-layout=$(_jq '.repoLayoutRef');xray-enable=${xray_enable}"

    if [[ "$repo_type" == "remote" ]]; then
      vars_string="${vars_string};repo-url=$(_jq '.url')"
    elif [[ "$repo_type" == "virtual" ]]; then
      vars_string="${vars_string};deploy-repo-name=$(_jq '.defaultDeploymentRepo');external-remote-repo-name=$(_jq '.externalDependenciesRemoteRepo');repos=$(_jq '.repositories')"
    fi

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
