#!/usr/bin/env bash
set -euo pipefail

project_name="${PROJECT_NAME:-}"
backend_dir="./.backend"

if [ -n "$project_name" ]; then
  binary_path="${backend_dir}/${project_name}"
else
  binary_path="$(find "$backend_dir" -maxdepth 1 -type f ! -name '*.exe' ! -name '*.sh' ! -name '*.cmd' ! -name 'pid' | head -n 1)"
fi

if [ -z "${binary_path:-}" ] || [ ! -f "$binary_path" ]; then
  echo "backend executable not found in $backend_dir" >&2
  exit 1
fi

chmod +x "$binary_path" >/dev/null 2>&1 || true

listen_addr="${LISTEN_ADDR:-http://127.0.0.1:12345}"
database_path="${DATABASE_PATH:-../storage/.data.json}"

exec "$binary_path" \
  --listen "$listen_addr" \
  --database "$database_path" \
  --pid "./.backend/pid"
