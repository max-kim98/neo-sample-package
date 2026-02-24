$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$projectName = (& (Join-Path $root "scripts/project-name.ps1")).Trim()
$expectedVersion = (& (Join-Path $root "scripts/version.ps1")).Trim()
$output = Join-Path $root "frontend/build"
$healthUrl = "http://127.0.0.1:12345/api/health"
$versionUrl = "http://127.0.0.1:12345/api/version"

$proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c .\\.backend\\start.cmd" -WorkingDirectory $output -PassThru

try {
  $ready = $false
  for ($i = 0; $i -lt 30; $i++) {
    try {
      Invoke-RestMethod -Method Get -Uri $healthUrl -TimeoutSec 2 | Out-Null
      $ready = $true
      break
    }
    catch {
      Start-Sleep -Seconds 1
    }
  }

  if (-not $ready) {
    throw "backend health endpoint not ready"
  }

  $version = Invoke-RestMethod -Method Get -Uri $versionUrl -TimeoutSec 2
  if ($version.version -ne $expectedVersion) {
    throw "version mismatch: expected $expectedVersion, got $($version.version)"
  }

  Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:12345/api/echo" -Body '{"message":"smoke"}' -ContentType 'application/json' | Out-Null
  Write-Output "smoke test passed"
}
finally {
  Push-Location $output
  try {
    cmd /c .\.backend\stop.cmd | Out-Null
  }
  finally {
    Pop-Location
  }
  if (-not $proc.HasExited) {
    $proc.Kill()
  }
}
