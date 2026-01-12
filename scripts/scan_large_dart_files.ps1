$repoRoot = $null
try {
  $repoRoot = (git rev-parse --show-toplevel).Trim()
} catch {
  $repoRoot = Split-Path -Parent $PSScriptRoot
}

try { Set-Location $repoRoot } catch { }

$roots = @('.\\lib', '.\\test')
$files = foreach ($root in $roots) {
  if (Test-Path $root) {
    Get-ChildItem -Path $root -Recurse -Filter '*.dart' -File -ErrorAction SilentlyContinue
  }
}

$files = $files | Where-Object { $_.Name -notmatch '\.(g|freezed)\.dart$' }

$out = @()
foreach ($f in $files) {
  $count = 0
  try {
    foreach ($null in [System.IO.File]::ReadLines($f.FullName)) {
      $count++
    }
  } catch {
    continue
  }

  if ($count -gt 300) {
    $rel = $f.FullName
    try {
      if ($repoRoot) {
        $rel = [System.IO.Path]::GetRelativePath($repoRoot, $f.FullName)
      }
    } catch {
    }
    $rel = $rel -replace '\\', '/'
    $out += "${rel}:$count"
  }
}

if ($out.Count -eq 0) {
  Write-Output 'OK: no Dart files > 300 lines'
  exit 0
}

$out | ForEach-Object { Write-Output $_ }
Write-Output 'ERROR: Dart files > 300 lines found'
exit 1
