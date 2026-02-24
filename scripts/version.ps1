function Normalize-Version {
  param([string]$Value)

  $normalized = $Value -replace '^refs/tags/', ''
  $normalized = $normalized -replace '^v', ''

  if ($normalized -match '^[0-9]+\.[0-9]+\.[0-9]+$') {
    return $normalized
  }

  return $null
}

if ($env:PACKAGE_VERSION) {
  $normalized = Normalize-Version $env:PACKAGE_VERSION
  if (-not $normalized) {
    Write-Error "invalid PACKAGE_VERSION: $env:PACKAGE_VERSION"
    exit 1
  }
  Write-Output $normalized
  exit 0
}

$candidates = @()

if ($env:GITHUB_REF_NAME) {
  $candidates += $env:GITHUB_REF_NAME
}

if ($env:GITHUB_REF) {
  $candidates += $env:GITHUB_REF
}

try {
  $gitTag = (git describe --tags --exact-match 2>$null).Trim()
  if ($gitTag) {
    $candidates += $gitTag
  }
}
catch {
}

foreach ($candidate in $candidates) {
  $normalized = Normalize-Version $candidate
  if ($normalized) {
    Write-Output $normalized
    exit 0
  }
}

Write-Output "0.0.0-dev"
