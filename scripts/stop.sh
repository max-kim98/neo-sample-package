#!/usr/bin/env bash
set -euo pipefail

pid_file="./.backend/pid"
if [ ! -f "$pid_file" ]; then
  exit 0
fi

pid="$(cat "$pid_file")"
if [ -n "$pid" ] && kill -0 "$pid" >/dev/null 2>&1; then
  kill "$pid" >/dev/null 2>&1 || true
fi

rm -f "$pid_file"
