param()

# Installs hooks from ./hooks into .git/hooks for this repository.
try { $top = (git rev-parse --show-toplevel) } catch { $top = Get-Location }
if (-not $top) { $top = Get-Location }
Set-Location $top

$src = Join-Path $top 'hooks'
$dst = Join-Path $top '.git\hooks'
if (-not (Test-Path $src)) {
    Write-Host "No hooks/ directory found at $src"
    exit 1
}

Get-ChildItem -Path $src -File | ForEach-Object {
    $dest = Join-Path $dst $_.Name
    Copy-Item -Path $_.FullName -Destination $dest -Force
    icacls $dest /grant "$(whoami)":RX | Out-Null 2>$null
    Write-Host "Installed hook: $($_.Name)"
}

Write-Host "All hooks installed."
