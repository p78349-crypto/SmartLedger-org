<#
.SYNOPSIS
Validate format of tools/INDEX_CODE_FEATURES.md (PowerShell).

.DESCRIPTION
Windows-friendly equivalent of tools/validate_index.sh.
Checks:
- INDEX table header separator exists (line starting with "|---")
- Table rows start with an ISO date (YYYY-MM-DD) after the first pipe
- Rows contain a minimum number of pipe separators (basic column shape check)

.EXAMPLE
pwsh ./tools/validate_index.ps1
#>
[CmdletBinding()]
param(
    [string]$Path
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$indexPath = if ($Path) { $Path } else { Join-Path $scriptDir 'INDEX_CODE_FEATURES.md' }

if (-not (Test-Path $indexPath)) {
    Write-Error "INDEX file not found: $indexPath"
    exit 2
}

$lines = Get-Content -LiteralPath $indexPath -Encoding UTF8

# Collect declared playbooks (for Note: Playbook=... validation)
$playbooks = New-Object 'System.Collections.Generic.HashSet[string]'
foreach ($l in $lines) {
    $m = [regex]::Match($l, '^###\s*Playbook:\s*(.+?)\s*$')
    if ($m.Success) {
        [void]$playbooks.Add($m.Groups[1].Value.Trim())
    }
}

$hasHeader = $false
$inTable = $false
$invalid = $false

# Only validate the Change Log table (the one that requires date rows).
$inChangeLogSection = $false
$foundChangeLogSection = $false

for ($i = 0; $i -lt $lines.Count; $i++) {
    $lineNo = $i + 1
    $line = $lines[$i]

    if (-not $foundChangeLogSection -and $line -match '^#\s*Change Log') {
        $inChangeLogSection = $true
        $foundChangeLogSection = $true
        continue
    }

    if (-not $inChangeLogSection) {
        continue
    }

    if ($line -match '^\|---') {
        $hasHeader = $true
        $inTable = $true
        continue
    }

    if (-not $inTable) {
        continue
    }

    # End of Change Log table (first non-table line after starting the table)
    if ($line -notmatch '^\|') {
        break
    }

    # Skip empty row lines like: |   |
    if ($line -match '^\|\s*\|') {
        continue
    }

    if ($line -notmatch '^\|\s*\d{4}-\d{2}-\d{2}\s*\|') {
        Write-Error "Invalid INDEX row format at line ${lineNo}: $line"
        $invalid = $true
        continue
    }

    # Mirror validate_index.sh's basic column-shape check
    $pipeCount = ([regex]::Matches($line, '\|')).Count
    if ($pipeCount -lt 4) {
        Write-Error "INDEX row at line ${lineNo} does not have enough columns: $line"
        $invalid = $true
    }

    # Optional: if Note contains Playbook=..., it must point to an existing playbook heading.
    try {
        $cells = $line.Split('|')
        $noteCell = if ($cells.Count -ge 6) { $cells[5].Trim() } else { '' }
        if (-not [string]::IsNullOrWhiteSpace($noteCell)) {
            $pm = [regex]::Match($noteCell, '(?:^|;\s*)Playbook\s*=\s*([^;]+)')
            if ($pm.Success) {
                $pb = $pm.Groups[1].Value.Trim()
                if (-not $playbooks.Contains($pb)) {
                    Write-Error "Unknown Playbook reference at line ${lineNo}: Playbook=${pb} (no matching '### Playbook: ${pb}' heading)"
                    $invalid = $true
                }
            }
        }
    } catch {
        # Ignore parsing issues; row format validation covers basics.
    }
}

if (-not $foundChangeLogSection) {
    Write-Error "Change Log section not found (# Change Log …)."
    exit 2
}

if (-not $hasHeader) {
    Write-Error "INDEX table header not found (|---)."
    exit 2
}

if ($invalid) {
    Write-Error 'INDEX format validation failed.'
    exit 1
}

Write-Host 'INDEX format validation passed.' -ForegroundColor Green
