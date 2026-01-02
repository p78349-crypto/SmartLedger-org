param(
  [Parameter(Mandatory = $true, Position = 0)]
  [string]$Path,

  [Parameter(Mandatory = $false)]
  [int]$MaxLevel = 6
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Path)) {
  throw "File not found: $Path"
}

$resolved = (Resolve-Path -LiteralPath $Path).Path
$lines = Get-Content -LiteralPath $resolved

# Markdown headings: # Title, ## Title, ... up to MaxLevel
$pattern = '^(#{1,' + $MaxLevel + '})\s+(.+?)\s*$'

for ($i = 0; $i -lt $lines.Count; $i++) {
  $line = $lines[$i]
  $m = [regex]::Match($line, $pattern)
  if (-not $m.Success) { continue }

  $hashes = $m.Groups[1].Value
  $title = $m.Groups[2].Value
  $level = $hashes.Length

  # 1-based line numbers (matches VS Code "Go to Line")
  $lineNumber = $i + 1
  $indent = ('  ' * ($level - 1))

  "{0,6}  {1}{2}" -f $lineNumber, $indent, $title
}
