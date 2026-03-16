Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$androidRoot = Join-Path $projectRoot 'android'
$keyPropertiesPath = Join-Path $androidRoot 'key.properties'

$hasKeytool = [bool](Get-Command keytool -ErrorAction SilentlyContinue)
$hasKeyProperties = Test-Path $keyPropertiesPath

$summary = [ordered]@{
    keytool = $hasKeytool
    keyProperties = $hasKeyProperties
    keystore = $false
    keyAlias = ''
    storeFile = ''
    hasStorePasswordInFile = $false
    hasKeyPasswordInFile = $false
    hasStorePasswordInEnv = $false
    hasKeyPasswordInEnv = $false
}

if ($hasKeyProperties) {
    $pairs = @{}
    foreach ($line in Get-Content -Path $keyPropertiesPath) {
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
        if ($trimmed.StartsWith('#')) { continue }
        $idx = $trimmed.IndexOf('=')
        if ($idx -lt 1) { continue }
        $k = $trimmed.Substring(0, $idx).Trim()
        $v = $trimmed.Substring($idx + 1).Trim()
        $pairs[$k] = $v
    }

    if ($pairs.ContainsKey('storeFile')) {
        $storeFile = $pairs['storeFile']
        $summary.storeFile = $storeFile
        $keystorePath = Join-Path (Join-Path $androidRoot 'app') $storeFile
        $summary.keystore = Test-Path $keystorePath
    }
    if ($pairs.ContainsKey('keyAlias')) {
        $summary.keyAlias = $pairs['keyAlias']
    }

    if ($pairs.ContainsKey('storePassword')) {
        $value = $pairs['storePassword']
        $summary.hasStorePasswordInFile =
            -not [string]::IsNullOrWhiteSpace($value) -and $value -ne '__FROM_ENV__'
    }
    if ($pairs.ContainsKey('keyPassword')) {
        $value = $pairs['keyPassword']
        $summary.hasKeyPasswordInFile =
            -not [string]::IsNullOrWhiteSpace($value) -and $value -ne '__FROM_ENV__'
    }
}

$summary.hasStorePasswordInEnv = -not [string]::IsNullOrWhiteSpace($env:SLD_STORE_PASSWORD)
$summary.hasKeyPasswordInEnv = -not [string]::IsNullOrWhiteSpace($env:SLD_KEY_PASSWORD)

$hasStorePassword = $summary.hasStorePasswordInEnv -or $summary.hasStorePasswordInFile
$hasKeyPassword = $summary.hasKeyPasswordInEnv -or $summary.hasKeyPasswordInFile

Write-Host '=== Android Release Signing Readiness ==='
Write-Host "keytool         : $($summary.keytool)"
Write-Host "key.properties  : $($summary.keyProperties)"
Write-Host "storeFile       : $($summary.storeFile)"
Write-Host "keystore exists : $($summary.keystore)"
Write-Host "keyAlias        : $($summary.keyAlias)"
Write-Host "storePass(src)  : $(if ($summary.hasStorePasswordInEnv) {'env'} elseif ($summary.hasStorePasswordInFile) {'file'} else {'missing'})"
Write-Host "keyPass(src)    : $(if ($summary.hasKeyPasswordInEnv) {'env'} elseif ($summary.hasKeyPasswordInFile) {'file'} else {'missing'})"

if (-not $summary.keytool) {
    Write-Host "[FAIL] keytool 미설치 또는 PATH 미등록" -ForegroundColor Red
    exit 1
}

if (-not $summary.keyProperties -or -not $summary.keystore -or -not $hasStorePassword -or -not $hasKeyPassword) {
    Write-Host "[ACTION] 아래 명령으로 릴리즈 서명 설정을 생성하세요:" -ForegroundColor Yellow
    Write-Host ".\\scripts\\setup_android_release_signing.ps1 -GenerateKeystore"
    Write-Host "[ACTION] 환경변수도 설정하세요:" -ForegroundColor Yellow
    Write-Host "  `$env:SLD_STORE_PASSWORD=\"...\""
    Write-Host "  `$env:SLD_KEY_PASSWORD=\"...\""
    exit 2
}

if ($summary.hasStorePasswordInFile -or $summary.hasKeyPasswordInFile) {
    Write-Host '[WARN] key.properties에 비밀번호가 평문 저장되어 있습니다. 환경변수 사용을 권장합니다.' -ForegroundColor Yellow
}

Write-Host '[OK] 릴리즈 서명 준비 완료' -ForegroundColor Green
exit 0