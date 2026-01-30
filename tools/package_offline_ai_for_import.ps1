# Package offline AI prototype files into a single zip for import into another project
# Usage: powershell -ExecutionPolicy Bypass -File .\tools\package_offline_ai_for_import.ps1
$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$tmp = Join-Path $root "tools\offline_ai_package_tmp_$stamp"
$zip = Join-Path $root "tools\offline_ai_package_$stamp.zip"

if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
New-Item -ItemType Directory -Path $tmp | Out-Null

# Files and folders to include (relative to repo root)
$items = @(
  "tools/offline_ai_server",
  "tools/OFFLINE_AI_ROADMAP.md",
  "scripts/install_vosk_model.ps1",
  "assets/ai/README.md",
  "lib/services/offline_ai_service.dart",
  "lib/widgets/voice_input_button.dart"
)

foreach ($i in $items) {
    $src = Join-Path $root $i
    if (-not (Test-Path $src)) { Write-Host "Warning: missing $i"; continue }
    $dest = Join-Path $tmp (Split-Path $i -Leaf)
    if (Test-Path $src -PathType Container) {
        Copy-Item -Path $src -Destination $dest -Recurse -Force
    } else {
        $destDir = Join-Path $tmp (Split-Path $i -Parent)
        if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }
        Copy-Item -Path $src -Destination (Join-Path $tmp $i) -Force
    }
}

# write a manifest
$manifest = @"
Offline AI Package Manifest

Created: $stamp
Includes:
- tools/offline_ai_server/*
- tools/OFFLINE_AI_ROADMAP.md
- scripts/install_vosk_model.ps1
- assets/ai/README.md
- lib/services/offline_ai_service.dart
- lib/widgets/voice_input_button.dart

Instructions:
- Unzip into your new project root or desired location.
- Follow tools/offline_ai_server/README.md to run the prototype server.
- Do NOT commit large model files into git; use model download or external hosting.
"@
$manifestPath = Join-Path $tmp "README_MANIFEST.txt"
$manifest | Out-File -FilePath $manifestPath -Encoding UTF8

# Create ZIP
if (Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $tmp "*") -DestinationPath $zip -Force

# Cleanup
Remove-Item -Recurse -Force $tmp

Write-Host "Package created: $zip"