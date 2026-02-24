# neo-sample-package

Frontend + backend sample package that follows the package guide and neo-cat style artifact layout.

## Project Name Rule

Package name is derived from the git `origin` repository name.

- Shell: `./scripts/project-name.sh`
- PowerShell: `./scripts/project-name.ps1`

Example:

- `https://github.com/max-kim98/neo-sample-package.git` -> `neo-sample-package`

The resolved project name is used for:

- backend binary names: `.backend/<project-name>` and `.backend/<project-name>.exe`
- frontend homepage: `/web/apps/<project-name>/`
- `/api/version` response `name`

## Version Rule

Version is resolved from a single source using:

- Shell: `./scripts/version.sh`
- PowerShell: `./scripts/version.ps1`

Resolution order:

1. `PACKAGE_VERSION` environment variable
2. current tag/ref (`vX.Y.Z` or `X.Y.Z`)
3. fallback `0.0.0-dev`

`/api/version` response `version` is injected at build time through `go build -ldflags`.

## Backend API

- `GET /api/health`
- `GET /api/version`
- `POST /api/echo`
- `GET /api/items`
- `POST /api/items`
- `DELETE /api/items/{id}`

## Packaging Output Contract

Final install output is `frontend/build/` with these required files:

- `frontend/build/index.html`
- `frontend/build/.backend.yml`
- `frontend/build/.backend/<project-name>`
- `frontend/build/.backend/<project-name>.exe`
- `frontend/build/.backend/start.sh`
- `frontend/build/.backend/stop.sh`
- `frontend/build/.backend/start.cmd`
- `frontend/build/.backend/stop.cmd`

## Local Commands

### Backend tests

```bash
go test ./backend -count=1
```

### Frontend tests

```bash
cd frontend
npm install --no-audit --no-fund
CI=true npm test
```

### Package + structure verify + smoke

```bash
./scripts/package.sh
./scripts/smoke.sh
```

Tag-style version override example:

```bash
PACKAGE_VERSION=v1.2.3 ./scripts/package.sh
PACKAGE_VERSION=v1.2.3 ./scripts/smoke.sh
```

On Windows:

```cmd
scripts\\package.cmd
powershell -ExecutionPolicy Bypass -File scripts\\smoke.ps1
```

## GitHub Actions

- CI workflow: `.github/workflows/ci.yml`
  - triggers: `push` to `main`, `pull_request`
  - matrix: `ubuntu-latest`, `macos-latest`, `windows-latest`
  - runs backend tests, frontend tests, package validation, smoke tests
- Release workflow: `.github/workflows/release.yml`
  - trigger: version tags (`v*` or `x.y.z`)
  - validates tag/version consistency before build
  - runs verification first, then creates GitHub release

## Branch and PR Rule

- create work branches as `issue-<number>`
- open a PR per issue branch
- merge only after CI passes

## Failure Conditions

Pipeline must fail when:

- release tag and resolved package version do not match
- smoke test `/api/version` does not match resolved version
- packaging output contract is violated
