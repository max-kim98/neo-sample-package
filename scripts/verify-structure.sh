#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output_dir="${1:-${root_dir}/frontend/build}"
project_name="${2:-$(${root_dir}/scripts/project-name.sh)}"

require_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "missing required file: $path" >&2
    exit 1
  fi
}

require_contains() {
  local path="$1"
  local text="$2"
  if ! grep -q "$text" "$path"; then
    echo "expected '$text' in $path" >&2
    exit 1
  fi
}

require_file "${root_dir}/LICENSE"
require_file "${output_dir}/index.html"
require_file "${output_dir}/.backend.yml"
require_file "${output_dir}/.backend/${project_name}"
require_file "${output_dir}/.backend/${project_name}.exe"
require_file "${output_dir}/.backend/start.sh"
require_file "${output_dir}/.backend/stop.sh"
require_file "${output_dir}/.backend/start.cmd"
require_file "${output_dir}/.backend/stop.cmd"

require_contains "${output_dir}/.backend.yml" "start:"
require_contains "${output_dir}/.backend.yml" "stop:"

echo "structure verification passed for ${project_name}"
