param(
  [string]$OutputDir = "",
  [string]$ProjectName = ""
)

$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
  $OutputDir = Join-Path $root "frontend/build"
}
if ([string]::IsNullOrWhiteSpace($ProjectName)) {
  $ProjectName = (& (Join-Path $root "scripts/project-name.ps1")).Trim()
}

function Require-File([string]$PathValue) {
  if (-not (Test-Path -Path $PathValue -PathType Leaf)) {
    throw "missing required file: $PathValue"
  }
}

Require-File (Join-Path $root "LICENSE")
Require-File (Join-Path $OutputDir "index.html")
Require-File (Join-Path $OutputDir ".backend.yml")
Require-File (Join-Path $OutputDir ".backend/$ProjectName")
Require-File (Join-Path $OutputDir ".backend/$ProjectName.exe")
Require-File (Join-Path $OutputDir ".backend/start.sh")
Require-File (Join-Path $OutputDir ".backend/stop.sh")
Require-File (Join-Path $OutputDir ".backend/start.cmd")
Require-File (Join-Path $OutputDir ".backend/stop.cmd")

$backendYaml = Get-Content (Join-Path $OutputDir ".backend.yml") -Raw
if ($backendYaml -notmatch "start:") {
  throw "expected start: in .backend.yml"
}
if ($backendYaml -notmatch "stop:") {
  throw "expected stop: in .backend.yml"
}

Write-Output "structure verification passed for $ProjectName"
