$repoRoot = $null
try {
  $repoRoot = (git rev-parse --show-toplevel).Trim()
} catch {
  $repoRoot = Split-Path -Parent $PSScriptRoot
}

try { Set-Location $repoRoot } catch { }

$roots = @('.\lib', '.\test')
$files = foreach ($root in $roots) {
  if (Test-Path $root) {
    Get-ChildItem -Path $root -Recurse -Filter '*.dart' -File -ErrorAction SilentlyContinue
  }
}

$files = $files | Where-Object { $_.Name -notmatch '\.(g|freezed)\.dart$' }

$out = @()
foreach ($f in $files) {
  $lineNo = 0
  Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue | ForEach-Object {
    $lineNo++
    $line = $_.ToString().TrimEnd("`r")
    if ($line.Length -le 80) { return }

    $rel = $f.FullName
    try {
      if ($repoRoot) {
        $rel = [System.IO.Path]::GetRelativePath($repoRoot, $f.FullName)
      }
    } catch {
    }
    $rel = $rel -replace '\\', '/'
    $out += "${rel}:${lineNo}:$($line.Length)"
  }
}

if ($out.Count -eq 0) {
  Write-Output 'OK: no lines > 80 chars'
  exit 0
}

$out | ForEach-Object { Write-Output $_ }
Write-Output 'ERROR: lines > 80 chars found'
exit 1
