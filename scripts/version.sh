#!/usr/bin/env bash
set -euo pipefail

normalize_version() {
  local raw="$1"
  local value="${raw#refs/tags/}"
  value="${value#v}"

  if [[ "$value" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    printf '%s\n' "$value"
    return 0
  fi

  return 1
}

if [[ -n "${PACKAGE_VERSION:-}" ]]; then
  if normalized="$(normalize_version "${PACKAGE_VERSION}")"; then
    printf '%s\n' "$normalized"
    exit 0
  fi
  printf 'invalid PACKAGE_VERSION: %s\n' "${PACKAGE_VERSION}" >&2
  exit 1
fi

candidates=()

if [[ -n "${GITHUB_REF_NAME:-}" ]]; then
  candidates+=("${GITHUB_REF_NAME}")
fi

if [[ -n "${GITHUB_REF:-}" ]]; then
  candidates+=("${GITHUB_REF}")
fi

git_tag="$(git describe --tags --exact-match 2>/dev/null || true)"
if [[ -n "${git_tag}" ]]; then
  candidates+=("${git_tag}")
fi

if ((${#candidates[@]} > 0)); then
  for candidate in "${candidates[@]}"; do
    if normalized="$(normalize_version "${candidate}")"; then
      printf '%s\n' "$normalized"
      exit 0
    fi
  done
fi

printf '0.0.0-dev\n'
