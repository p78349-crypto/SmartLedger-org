param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Since
)

$indexFile = Join-Path $PSScriptRoot 'INDEX_CODE_FEATURES.md'

if (-not (Test-Path -LiteralPath $indexFile)) {
  Write-Error "INDEX file not found: $indexFile"
  exit 2
}

if ([string]::IsNullOrWhiteSpace($Since)) {
  Write-Error 'Usage: generate_release_notes.ps1 <since-date YYYY-MM-DD>'
  exit 2
}

if ($Since -notmatch '^\d{4}-\d{2}-\d{2}$') {
  Write-Error "Invalid since-date format: '$Since' (expected YYYY-MM-DD)"
  exit 2
}

$inTable = $false

Get-Content -LiteralPath $indexFile | ForEach-Object {
  $line = $_

  if ($line -match '^\|---') {
    $inTable = $true
    return
  }

  if (-not $inTable) {
    return
  }

  if ($line -match '^\|\s*\d{4}-\d{2}-\d{2}\s*\|') {
    $parts = $line -split '\|'
    if ($parts.Count -ge 3) {
      $date = $parts[1].Trim()
      if ($date -ge $Since) {
        if ($line.StartsWith('|')) {
          Write-Output (' - ' + $line.Substring(1))
        } else {
          Write-Output (' - ' + $line)
        }
      }
    }
  }
}
