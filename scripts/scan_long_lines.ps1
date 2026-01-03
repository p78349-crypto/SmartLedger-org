try { Set-Location (git rev-parse --show-toplevel) } catch { }
$files = Get-ChildItem -Path .\lib -Recurse -Filter '*.dart' -File -ErrorAction SilentlyContinue
$out = @()
$found = $false
foreach ($f in $files) {
  $lines = Get-Content -LiteralPath $f.FullName -ErrorAction SilentlyContinue
  for ($i=0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i].ToString().TrimEnd("`r")
    if ($line.Length -gt 80) { $out += "$($f.FullName):$($i+1):$($line.Length)"; $found = $true }
  }
}
if ($out.Count -eq 0) {
  Write-Host 'NO_LONG_LINES'
  exit 0
} else {
  $out | ForEach-Object { Write-Host $_ }
  Write-Host 'LONG_LINES_FOUND'
  exit 1
}
