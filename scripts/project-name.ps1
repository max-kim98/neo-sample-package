param(
  [string]$RemoteUrl = ""
)

if ([string]::IsNullOrWhiteSpace($RemoteUrl)) {
  try {
    $RemoteUrl = (& git remote get-url origin).Trim()
  }
  catch {
    $RemoteUrl = ""
  }
}

if ([string]::IsNullOrWhiteSpace($RemoteUrl)) {
  Write-Error "unable to resolve project name: no origin remote URL"
  exit 1
}

$trimmed = $RemoteUrl
if ($trimmed.EndsWith('.git')) {
  $trimmed = $trimmed.Substring(0, $trimmed.Length - 4)
}

$pathPart = $trimmed
if ($pathPart -match '^[^:]+://[^/]+/(.+)$') {
  $pathPart = $Matches[1]
} elseif ($pathPart -match '^git@[^:]+:(.+)$') {
  $pathPart = $Matches[1]
}

$projectName = Split-Path -Path $pathPart -Leaf

if ([string]::IsNullOrWhiteSpace($projectName)) {
  Write-Error "unable to resolve project name from remote URL: $RemoteUrl"
  exit 1
}

Write-Output $projectName
