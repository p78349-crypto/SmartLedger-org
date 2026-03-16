<#
PowerShell helper to build Flutter release with symbol obfuscation.
Usage:
  .\build_release_obfuscate.ps1 -Platform android
  .\build_release_obfuscate.ps1 -Platform ios
  .\build_release_obfuscate.ps1 -Platform all

This script runs `flutter build` with `--obfuscate` and
`--split-debug-info` so mapping files are written to
`build/debug-info/<platform>` for safe storage.
#>
param(
    [ValidateSet('android','ios','all')]
    [string]$Platform = 'android'
)

if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: 'flutter' 명령을 not found. Flutter가 설치되어 있고 PATH에 있는지 확인하세요." -ForegroundColor Red
    exit 1
}

switch ($Platform) {
    'android' {
        Write-Host "Building Android release (obfuscated)..."
        flutter build apk --release --obfuscate --split-debug-info=build/debug-info/android
    }
    'ios' {
        Write-Host "Building iOS release (obfuscated)..."
        flutter build ios --release --obfuscate --split-debug-info=build/debug-info/ios
    }
    'all' {
        Write-Host "Building Android and iOS releases (obfuscated)..."
        flutter build apk --release --obfuscate --split-debug-info=build/debug-info/android
        flutter build ios --release --obfuscate --split-debug-info=build/debug-info/ios
    }
}

Write-Host "Done. Keep the mapping files under 'build/debug-info/<platform>' safe for symbolication." -ForegroundColor Green
