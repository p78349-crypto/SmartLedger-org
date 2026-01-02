<#
.SYNOPSIS
Add an INDEX entry with auto-collected changed file paths.

.DESCRIPTION
Wrapper around tools/add-index-entry.ps1.
- Auto-fills Files from git (staged + unstaged by default)
- Can stage tools/INDEX_CODE_FEATURES.md without prompting (use -Stage)

Typical usage:
  pwsh ./tools/add-index-entry-auto.ps1
  pwsh ./tools/add-index-entry-auto.ps1 -What "Fix: ..." -Stage

Notes:
- If git is not available or no changes are found, Files will be left empty.
- The underlying script remains the single writer of the INDEX row.
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

    # If you pass -Files explicitly, auto-collection will be skipped.
    [string]$Files,

    # Auto collection knobs
    [switch]$IncludeStaged,
    [switch]$IncludeUnstaged,
    [switch]$IncludeUntracked,

    [switch]$Stage
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$inner = Join-Path $scriptDir 'add-index-entry.ps1'
if (-not (Test-Path -LiteralPath $inner)) {
    Write-Error "Inner script not found: $inner"
    exit 1
}

function Get-GitChangedFiles {
    param(
        [bool]$wantStaged,
        [bool]$wantUnstaged,
        [bool]$wantUntracked
    )

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        return @()
    }

    $result = New-Object 'System.Collections.Generic.List[string]'

    if ($wantUnstaged) {
        $paths = & git diff --name-only
        if ($LASTEXITCODE -eq 0 -and $paths) {
            foreach ($p in $paths) {
                if (-not [string]::IsNullOrWhiteSpace($p)) { $result.Add($p.Trim()) }
            }
        }
    }

    if ($wantStaged) {
        $paths = & git diff --cached --name-only
        if ($LASTEXITCODE -eq 0 -and $paths) {
            foreach ($p in $paths) {
                if (-not [string]::IsNullOrWhiteSpace($p)) { $result.Add($p.Trim()) }
            }
        }
    }

    if ($wantUntracked) {
        $paths = & git ls-files --others --exclude-standard
        if ($LASTEXITCODE -eq 0 -and $paths) {
            foreach ($p in $paths) {
                if (-not [string]::IsNullOrWhiteSpace($p)) { $result.Add($p.Trim()) }
            }
        }
    }

    # unique, stable order
    $unique = @(
        $result |
            Where-Object { $_ -and $_.Trim() -ne '' } |
            Select-Object -Unique
    )
    return $unique
}

if ($null -eq $Files -or [string]::IsNullOrWhiteSpace($Files)) {
    $wantStaged = $IncludeStaged.IsPresent
    $wantUnstaged = $IncludeUnstaged.IsPresent

    # Default behavior: include both staged+unstaged if neither switch was specified.
    if (-not $wantStaged -and -not $wantUnstaged) {
        $wantStaged = $true
        $wantUnstaged = $true
    }

    $auto = @(
        Get-GitChangedFiles -wantStaged $wantStaged -wantUnstaged $wantUnstaged -wantUntracked $IncludeUntracked.IsPresent
    )
    if ($auto.Count -gt 0) {
        $Files = ($auto -join ', ')
    }
}

$callParams = @{
    Date = $Date
    What = $What
    Old = $Old
    New = $New
    Playbook = $Playbook
    Why = $Why
    Verify = $Verify
    Risk = $Risk
    Tests = $Tests
    Note = $Note
    Files = $Files
}

if ($Stage) {
    & $inner @callParams -Stage
} else {
    & $inner @callParams
}
