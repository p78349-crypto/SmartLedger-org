param(
    [string]$WorkspaceRoot = "."
)

$ErrorActionPreference = 'Stop'

$root = Resolve-Path $WorkspaceRoot
$logFiles = @(
    (Join-Path $root "EPUB\WORK_LOG_DETAIL.md"),
    (Join-Path $root "OCR,Translation\WORK_LOG_DETAIL.md")
)

$passToken = "모듈화 계획: PASS"
$found = $false
$foundIn = @()

foreach ($path in $logFiles) {
    if (-not (Test-Path $path)) {
        continue
    }

    $readArgs = @{
        Path = $path
        TotalCount = 120
        ErrorAction = 'SilentlyContinue'
    }
    $head = Get-Content @readArgs
    if (($head -join "`n") -match [regex]::Escape($passToken)) {
        $found = $true
        $foundIn += $path
    }
}

if ($found) {
    Write-Output "모듈화 계획: PASS"
    foreach ($item in $foundIn) {
        Write-Output ("- 확인 파일: {0}" -f $item)
    }
    exit 0
}

Write-Output "모듈화 계획: FAIL"
Write-Output "작업 로그 상단에 '모듈화 계획: PASS'를 먼저 기록하세요."
Write-Output "대상: EPUB/WORK_LOG_DETAIL.md 또는 OCR,Translation/WORK_LOG_DETAIL.md"
exit 1
