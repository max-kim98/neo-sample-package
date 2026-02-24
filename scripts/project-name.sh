#!/usr/bin/env bash
set -euo pipefail

remote_url="${1:-}"
if [ -z "$remote_url" ]; then
  remote_url="$(git remote get-url origin 2>/dev/null || true)"
fi

if [ -z "$remote_url" ]; then
  echo "unable to resolve project name: no origin remote URL" >&2
  exit 1
fi

trimmed="${remote_url%.git}"
path_part="$(printf '%s' "$trimmed" | sed -E 's#^[^:]+://[^/]+/##; s#^git@[^:]+:##')"
project_name="$(basename "$path_part")"

if [ -z "$project_name" ] || [ "$project_name" = "$trimmed" ]; then
  echo "unable to resolve project name from remote URL: $remote_url" >&2
  exit 1
fi

printf '%s\n' "$project_name"
