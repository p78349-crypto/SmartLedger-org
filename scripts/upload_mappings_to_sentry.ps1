param(
  [string]$Platform = 'android'
)

if (-not $env:SENTRY_AUTH_TOKEN) {
  Write-Host "SENTRY_AUTH_TOKEN not set. Aborting." -ForegroundColor Yellow
  exit 1
}
if (-not $env:SENTRY_ORG -or -not $env:SENTRY_PROJECT) {
  Write-Host "SENTRY_ORG or SENTRY_PROJECT not set. Aborting." -ForegroundColor Yellow
  exit 1
}

$mappingDir = "build/debug-info/$Platform"
if (-not (Test-Path $mappingDir)) {
  Write-Host "Mapping directory '$mappingDir' not found. Run obfuscated build first." -ForegroundColor Red
  exit 1
}

# Try to download/install sentry-cli
if (-not (Get-Command sentry-cli -ErrorAction SilentlyContinue)) {
  Write-Host "Installing sentry-cli..."
  Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://sentry.io/get-cli/'))
}

Write-Host "Uploading debug info to Sentry..."
sentry-cli upload-dif --org $env:SENTRY_ORG --project $env:SENTRY_PROJECT $mappingDir

Write-Host "Done."
