# PowerShell helper: download a Vosk Korean model to tools/offline_ai_server/models
# Usage: .\install_vosk_model.ps1 -DestPath ..\tools\offline_ai_server\models
param(
    [string]$DestPath = "..\tools\offline_ai_server\models",
    [string]$Url = "https://alphacephei.com/vosk/models/vosk-model-small-ko-0.22.zip"
)

$dest = Join-Path -Path (Get-Location) -ChildPath $DestPath
if (-not (Test-Path $dest)) { New-Item -ItemType Directory -Path $dest | Out-Null }
$tmp = [IO.Path]::Combine($env:TEMP, [IO.Path]::GetFileName($Url))
Write-Host "Downloading $Url to $tmp ..."
Invoke-WebRequest -Uri $Url -OutFile $tmp
Write-Host "Extracting to $dest ..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($tmp, $dest)
Write-Host "Model installed to $dest"