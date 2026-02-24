$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$projectName = (& (Join-Path $root "scripts/project-name.ps1")).Trim()
$output = Join-Path $root "frontend/build"
$healthUrl = "http://127.0.0.1:12345/api/health"

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

  Invoke-RestMethod -Method Post -Uri "http://127.0.0.1:12345/api/echo" -Body '{"message":"smoke"}' -ContentType 'application/json' | Out-Null
  Write-Output "smoke test passed"
}
finally {
  cmd /c .\.backend\stop.cmd | Out-Null
  if (-not $proc.HasExited) {
    $proc.Kill()
  }
}
