param(
    [string]$KeystoreFileName = 'smartledger-release.jks',
    [string]$KeyAlias = 'smartledger',
    [int]$ValidityDays = 10000,
    [string]$StorePassword,
    [string]$KeyPassword,
    [string]$DName = 'CN=SmartLedger, OU=Mobile, O=SmartLedger, L=Seoul, ST=Seoul, C=KR',
    [switch]$PersistPasswords,
    [switch]$GenerateKeystore,
    [switch]$ForceOverwrite
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$androidRoot = Join-Path $projectRoot 'android'
$appDir = Join-Path $androidRoot 'app'
$keyPropertiesPath = Join-Path $androidRoot 'key.properties'
$keystorePath = Join-Path $appDir $KeystoreFileName

function Read-SecretText([string]$Prompt) {
    $secure = Read-Host -Prompt $Prompt -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    }
    finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

if ([string]::IsNullOrWhiteSpace($StorePassword)) {
    $StorePassword = Read-SecretText 'Keystore 비밀번호 입력'
}

if ([string]::IsNullOrWhiteSpace($KeyPassword)) {
    $KeyPassword = Read-SecretText 'Key 비밀번호 입력(미입력 시 keystore 비밀번호와 동일하게 입력)'
    if ([string]::IsNullOrWhiteSpace($KeyPassword)) {
        $KeyPassword = $StorePassword
    }
}

if ([string]::IsNullOrWhiteSpace($StorePassword) -or [string]::IsNullOrWhiteSpace($KeyPassword)) {
    throw '비밀번호가 비어 있습니다. 배포 키 설정을 중단합니다.'
}

if ($StorePassword.Length -lt 6 -or $KeyPassword.Length -lt 6) {
    throw 'keytool 제약으로 비밀번호는 최소 6자 이상이어야 합니다.'
}

if (-not (Test-Path $appDir)) {
    throw "Android app 디렉터리를 찾을 수 없습니다: $appDir"
}

$keystoreExists = Test-Path $keystorePath

if (-not $keystoreExists -or $GenerateKeystore.IsPresent) {
    $keytool = Get-Command keytool -ErrorAction SilentlyContinue
    if (-not $keytool) {
        throw "'keytool' 명령을 찾을 수 없습니다. JDK 설치 및 PATH 설정 후 다시 실행하세요."
    }

    if ($keystoreExists -and -not $ForceOverwrite.IsPresent) {
        throw "Keystore가 이미 존재합니다: $keystorePath`n덮어쓰려면 -ForceOverwrite 를 사용하세요."
    }

    if ($keystoreExists -and $ForceOverwrite.IsPresent) {
        Remove-Item -Path $keystorePath -Force
    }

    Write-Host "Generating release keystore: $keystorePath"

    & $keytool.Source `
        -genkeypair `
        -v `
        -keystore $keystorePath `
        -alias $KeyAlias `
        -keyalg RSA `
        -keysize 2048 `
        -validity $ValidityDays `
        -storepass $StorePassword `
        -keypass $KeyPassword `
        -dname $DName | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "keytool 실행 실패(ExitCode=$LASTEXITCODE). 비밀번호/alias/경로를 확인하세요."
    }

    if (-not (Test-Path $keystorePath)) {
        throw "keystore 파일이 생성되지 않았습니다: $keystorePath"
    }

    Write-Host 'Keystore 생성 완료'
}
else {
    Write-Host "기존 keystore 사용: $keystorePath"
}

# build.gradle.kts(app 모듈) 기준 상대경로
$storeFileValue = $KeystoreFileName

if ($PersistPasswords.IsPresent) {
    Write-Warning '비밀번호를 key.properties에 평문 저장합니다. 권장되지 않습니다.'
    $content = @(
        "storePassword=$StorePassword"
        "keyPassword=$KeyPassword"
        "keyAlias=$KeyAlias"
        "storeFile=$storeFileValue"
    ) -join [Environment]::NewLine
}
else {
    $content = @(
        '# 비밀번호 하드코딩 금지: 아래 값은 환경변수에서 읽습니다.'
        '# PowerShell: $env:SLD_STORE_PASSWORD="..."; $env:SLD_KEY_PASSWORD="..."'
        'storePassword=__FROM_ENV__'
        'keyPassword=__FROM_ENV__'
        "keyAlias=$KeyAlias"
        "storeFile=$storeFileValue"
    ) -join [Environment]::NewLine
}

if ((Test-Path $keyPropertiesPath) -and -not $ForceOverwrite.IsPresent) {
    Write-Host "key.properties가 이미 존재합니다: $keyPropertiesPath"
    Write-Host '기존 파일을 유지합니다. 갱신하려면 -ForceOverwrite 옵션을 사용하세요.'
}
else {
    Set-Content -Path $keyPropertiesPath -Value $content -Encoding UTF8
    Write-Host "key.properties 생성/갱신 완료: $keyPropertiesPath"
}

Write-Host ''
Write-Host '다음 단계:'
Write-Host '0) 현재 세션 환경변수 설정(비밀번호 하드코딩 금지)'
Write-Host "   `$env:SLD_STORE_PASSWORD=`"<your_password>`""
Write-Host "   `$env:SLD_KEY_PASSWORD=`"<your_password>`""
Write-Host '1) flutter build appbundle --release'
Write-Host '2) 생성된 AAB를 Play Console에 업로드'