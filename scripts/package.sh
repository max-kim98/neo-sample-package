#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_name="$(${root_dir}/scripts/project-name.sh)"
package_version="$(${root_dir}/scripts/version.sh)"
export PROJECT_NAME="$project_name"
export PACKAGE_VERSION="$package_version"
export PATH="/opt/homebrew/bin:$PATH"
export GOCACHE="${GOCACHE:-${root_dir}/.cache/go-build}"
export GOMODCACHE="${GOMODCACHE:-${root_dir}/.cache/go-mod}"
mkdir -p "$GOCACHE" "$GOMODCACHE"

node "${root_dir}/scripts/set-frontend-homepage.js" "$project_name"

pushd "${root_dir}/frontend" >/dev/null
if [ ! -d "node_modules" ]; then
  npm install --no-audit --no-fund
else
  echo "frontend/node_modules already exists, skipping npm install"
fi
PUBLIC_URL="/web/apps/${project_name}" npm run build
popd >/dev/null

mkdir -p "${root_dir}/frontend/build/.backend"

pushd "${root_dir}" >/dev/null
native_goos="$(go env GOOS)"
native_goarch="$(go env GOARCH)"
ldflags="-X github.com/max-kim98/neo-sample-package/backend.Version=${package_version}"
CGO_ENABLED=0 GOOS="${native_goos}" GOARCH="${native_goarch}" go build -ldflags "${ldflags}" -o "${root_dir}/frontend/build/.backend/${project_name}" .
CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build -ldflags "${ldflags}" -o "${root_dir}/frontend/build/.backend/${project_name}.exe" .
popd >/dev/null

cp "${root_dir}/scripts/start.sh" "${root_dir}/frontend/build/.backend/start.sh"
cp "${root_dir}/scripts/stop.sh" "${root_dir}/frontend/build/.backend/stop.sh"
cp "${root_dir}/scripts/start.cmd" "${root_dir}/frontend/build/.backend/start.cmd"
cp "${root_dir}/scripts/stop.cmd" "${root_dir}/frontend/build/.backend/stop.cmd"
cp "${root_dir}/.backend.yml" "${root_dir}/frontend/build/.backend.yml"

chmod +x "${root_dir}/frontend/build/.backend/${project_name}"
chmod +x "${root_dir}/frontend/build/.backend/start.sh"
chmod +x "${root_dir}/frontend/build/.backend/stop.sh"

"${root_dir}/scripts/verify-structure.sh" "${root_dir}/frontend/build" "$project_name"
