<#
.SYNOPSIS
Interactive helper to add an INDEX line to tools/INDEX_CODE_FEATURES.md.

.DESCRIPTION
Prompts for fields and inserts a Markdown table row under the INDEX table header.
Optionally stages the modified file for commit.

By default, the row is inserted into the "# Change Log" table in tools/INDEX_CODE_FEATURES.md.

.EXAMPLE
pwsh ./tools/add-index-entry.ps1
pwsh ./tools/add-index-entry.ps1 -What "CI index check" -Why "PR에서 INDEX 누락 방지" -Verify "tools/validate_index.sh" -Files ".github/workflows/index-check.yml" -Stage
#>
[CmdletBinding()]
param(
    [string]$Date = $(Get-Date -Format yyyy-MM-dd),
    [string]$What,
    [string]$Old,
    [string]$New,
    [string]$Playbook,
    [string]$Why,
    [string]$Verify,
    [string]$Risk,
    [string]$Tests,
    [string]$Note,
    [string]$Files,
    [switch]$Stage
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexPath = Join-Path $scriptDir 'INDEX_CODE_FEATURES.md'
if (-not (Test-Path $indexPath)) {
    Write-Error "INDEX file not found at $indexPath"
    exit 1
}

if ([string]::IsNullOrWhiteSpace($What)) { $What = Read-Host 'What changed (short title)' }
if ($null -eq $Old) { $Old = Read-Host 'Old (short descriptor, optional)' }
if ($null -eq $New) { $New = Read-Host 'New (short descriptor, optional)' }
if ($null -eq $Playbook) { $Playbook = Read-Host 'Playbook (screen/module ref, optional; e.g., AccountMainScreen)' }
if ($null -eq $Why) { $Why = Read-Host 'Why (reason/context, optional)' }
if ($null -eq $Verify) { $Verify = Read-Host 'Verify (how you checked, optional)' }
if ($null -eq $Risk) { $Risk = Read-Host 'Risk (edge cases / rollback, optional)' }
if ($null -eq $Tests) { $Tests = Read-Host 'Tests (flutter test/analyze/task, optional)' }
if ($null -eq $Note) { $Note = Read-Host 'Note (optional; you can include file paths here)' }
if ($null -eq $Files) { $Files = Read-Host 'Files (comma-separated relative paths, optional)' }

function Add-NotePart([string]$label, [string]$value) {
    if ([string]::IsNullOrWhiteSpace($value)) { return }
    if ([string]::IsNullOrWhiteSpace($script:Note)) {
        $script:Note = "$label=$value"
    } else {
        $script:Note = "$script:Note; $label=$value"
    }
}

Add-NotePart 'Playbook' $Playbook
Add-NotePart 'Why' $Why
Add-NotePart 'Verify' $Verify
Add-NotePart 'Risk' $Risk
Add-NotePart 'Tests' $Tests
if (-not [string]::IsNullOrWhiteSpace($Files)) { Add-NotePart 'Files' $Files }

# Construct the Markdown row
$row = "| $Date | $What | $Old | $New | $Note |"

# Read file as lines and find the first table header separator line (|---|---|...)
$lines = Get-Content -LiteralPath $indexPath -Encoding UTF8 -ErrorAction Stop
$insertAfter = -1

# Prefer the Change Log table under "# Change Log".
$changeLogStart = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^#\s+Change\s+Log\b') {
        $changeLogStart = $i
        break
    }
}

if ($changeLogStart -ge 0) {
    for ($i = $changeLogStart; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\|---') {
            $insertAfter = $i
            break
        }
    }
}

# Fallback: find the first table header separator line (legacy behavior)
if ($insertAfter -eq -1) {
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match '^\|---') {
            $insertAfter = $i
            break
        }
    }
}

if ($insertAfter -eq -1) {
    Write-Host "Could not find INDEX table header — appending to end of file." -ForegroundColor Yellow
    Add-Content -Encoding UTF8 -Path $indexPath -Value $row
} else {
    $before = $lines[0..$insertAfter]
    if (($insertAfter + 1) -le ($lines.Count - 1)) {
        $after = $lines[($insertAfter + 1)..($lines.Count - 1)]
        $newContent = $before + $row + $after
    } else {
        $newContent = $before + $row
    }
    $newContent -join "`n" | Set-Content -Encoding UTF8 -Path $indexPath
}

Write-Host "Added INDEX entry:" -ForegroundColor Green
Write-Host $row

$shouldStage = $false
if ($Stage) {
    $shouldStage = $true
} else {
    $answer = Read-Host 'Stage tools/INDEX_CODE_FEATURES.md now? (Y/n)'
    if ($answer -notmatch '^[nN]') {
        $shouldStage = $true
    }
}

if ($shouldStage) {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        git add "$indexPath"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Staged $indexPath" -ForegroundColor Green
        } else {
            Write-Host "Failed to stage (is this a git repo?)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Git not available in PATH — cannot stage." -ForegroundColor Yellow
    }
}

Write-Host "Done. Please review tools/INDEX_CODE_FEATURES.md and include a short human-friendly summary if needed." -ForegroundColor Cyan
