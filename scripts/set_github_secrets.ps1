param(
  [string]$Repo = $env:GITHUB_REPOSITORY
)

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  Write-Host "gh CLI not found. Install GitHub CLI and authenticate first." -ForegroundColor Red
  exit 1
}

if (-not $Repo) {
  $Repo = Read-Host "Enter target repository (owner/repo)"
}

function Set-SecretInteractive([string]$name) {
  $val = (Get-Item -Path Env:$name -ErrorAction SilentlyContinue).Value
  if (-not $val) {
    $val = Read-Host "Enter value for $name"
  }
  gh secret set $name --repo $Repo --body $val
}

Set-SecretInteractive -name 'SENTRY_AUTH_TOKEN'
Set-SecretInteractive -name 'SENTRY_ORG'
Set-SecretInteractive -name 'SENTRY_PROJECT'

Write-Host "All done. Secrets set for $Repo." -ForegroundColor Green
