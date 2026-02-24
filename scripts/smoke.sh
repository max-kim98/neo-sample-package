#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_name="$(${root_dir}/scripts/project-name.sh)"
output_dir="${root_dir}/frontend/build"
health_url="http://127.0.0.1:12345/api/health"

echo "starting backend for smoke test..."
(
  cd "$output_dir"
  PROJECT_NAME="$project_name" ./.backend/start.sh > "${root_dir}/smoke.log" 2>&1
) &
start_pid=$!

cleanup() {
  (
    cd "$output_dir"
    ./.backend/stop.sh >/dev/null 2>&1 || true
  )
  wait "$start_pid" 2>/dev/null || true
}
trap cleanup EXIT

for _ in $(seq 1 30); do
  if curl -sf "$health_url" >/dev/null; then
    break
  fi
  sleep 1
done

curl -sf "$health_url" >/dev/null

curl -sf -X POST "$health_url" -o /dev/null >/dev/null 2>&1 || true
curl -sf -X POST http://127.0.0.1:12345/api/echo \
  -H 'Content-Type: application/json' \
  -d '{"message":"smoke"}' >/dev/null

echo "smoke test passed"
