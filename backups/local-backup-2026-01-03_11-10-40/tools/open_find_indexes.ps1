param(
  [switch]$ReuseWindow
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$parent = Join-Path $repoRoot 'tools\INDEX_PARENT.md'
$child = Join-Path $repoRoot 'tools\INDEX_CHILD.md'

if (!(Test-Path $parent)) {
  throw "Missing file: $parent"
}
if (!(Test-Path $child)) {
  throw "Missing file: $child"
}

function Open-WithCode {
  param(
    [Parameter(Mandatory = $true)][string]$Path,
    [switch]$ReuseWindow
  )

  $codeCmd = Get-Command code -ErrorAction SilentlyContinue
  if ($null -eq $codeCmd) {
    return $false
  }

  if ($ReuseWindow) {
    & $codeCmd.Path -r $Path | Out-Null
  } else {
    & $codeCmd.Path $Path | Out-Null
  }

  return $true
}

$opened = Open-WithCode -Path $parent -ReuseWindow:$ReuseWindow
$opened = (Open-WithCode -Path $child -ReuseWindow:$ReuseWindow) -or $opened

if (-not $opened) {
  Start-Process $parent | Out-Null
  Start-Process $child | Out-Null
}

Write-Host "Opened: tools/INDEX_PARENT.md"
Write-Host "Opened: tools/INDEX_CHILD.md"
