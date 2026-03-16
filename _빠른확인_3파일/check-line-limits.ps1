param(
    [string]$Root = ".",
    [int]$MaxLen = 80
)

$rootPath = Resolve-Path $Root
$exts = @(".py", ".ps1", ".sh")
$excludeDirs = @(
    "venv", ".venv", "backups", "__pycache__", "node_modules",
    "build", "dist",
    "piper-rs", "Kokoro-82M", "gemma-2-2b-it", "gemma-3n-E4B-it",
    "nllb-200-1.3B", "nllb-200-3.3B", "nllb-200-distilled-600M",
    "LightOnOCR-2-1B", "trial", "배포파일",
    "배포_구매자용", "배포_판매자전용"
)
$excludeFileNamePatterns = @(
    "*_ORIG_before_*"
)

function Is-Excluded {
    param([string]$Path, [string]$Name)

    $normalized = $Path -replace '/', '\\'

    foreach ($pattern in $excludeFileNamePatterns) {
        if ($Name -like $pattern) {
            return $true
        }
    }

    foreach ($dirName in $excludeDirs) {
        $mid = '*\\' + $dirName + '\\*'
        $end = '*\\' + $dirName
        if ($normalized -like $mid) {
            return $true
        }
        if ($normalized -like $end) {
            return $true
        }
    }
    return $false
}

$violations = @()
$files = Get-ChildItem -Path $rootPath -Recurse -File |
    Where-Object { $exts -contains $_.Extension }

foreach ($file in $files) {
    if (Is-Excluded -Path $file.FullName -Name $file.Name) {
        continue
    }

    $lineNum = 0
    foreach ($line in Get-Content $file.FullName) {
        $lineNum++
        if ($line.Length -gt $MaxLen) {
            $violations += [PSCustomObject]@{
                File = $file.FullName
                Line = $lineNum
                Length = $line.Length
            }
        }
    }
}

if ($violations.Count -eq 0) {
    Write-Output "PASS: 한 줄 길이 초과 위반 없음 (> $MaxLen자)."
    exit 0
}

Write-Output "FAIL: 한 줄 길이 위반 $($violations.Count)건 발견 (> $MaxLen자)."
$violations | Select-Object -First 50 | ForEach-Object {
    Write-Output ("{0}:{1} len={2}" -f $_.File, $_.Line, $_.Length)
}

if ($violations.Count -gt 50) {
    $remaining = $violations.Count - 50
    Write-Output "...and $remaining more."
}

exit 1
