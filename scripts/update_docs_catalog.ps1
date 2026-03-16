param(
    [string]$DocsRoot = (Join-Path $PSScriptRoot '..\docs'),
    [string]$OutputFile = ''
)

$resolvedDocsRoot = (Resolve-Path $DocsRoot).Path
$hubDir = Join-Path $resolvedDocsRoot 'hub'

if (-not (Test-Path $hubDir)) {
    New-Item -ItemType Directory -Path $hubDir | Out-Null
}

if ([string]::IsNullOrWhiteSpace($OutputFile)) {
    $OutputFile = Join-Path $hubDir 'DOCS_MASTER_CATALOG.md'
}

$resolvedOutputFile = [System.IO.Path]::GetFullPath($OutputFile)

$files = Get-ChildItem -Path $resolvedDocsRoot -Recurse -File -Filter '*.md' |
    Sort-Object FullName

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('# Docs Master Catalog')
$lines.Add('')
$lines.Add('> 자동 생성 인덱스: docs 폴더 내 Markdown 문서 전체 목록')
$lines.Add("> 생성일: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$lines.Add("> 문서 수: $($files.Count)")
$lines.Add('')
$lines.Add('---')
$lines.Add('')

$groups = $files | Group-Object {
    $relativeDir = [System.IO.Path]::GetRelativePath($resolvedDocsRoot, $_.DirectoryName).Replace('\\', '/')
    if ([string]::IsNullOrWhiteSpace($relativeDir) -or $relativeDir -eq '.') { '.' } else { $relativeDir }
}

foreach ($group in ($groups | Sort-Object Name)) {
    $section = if ($group.Name -eq '.') { 'docs (root)' } else { "docs/$($group.Name)" }
    $lines.Add("## $section")

    foreach ($file in ($group.Group | Sort-Object Name)) {
        $relativeFromHub = [System.IO.Path]::GetRelativePath($hubDir, $file.FullName).Replace('\\', '/')
        $display = $file.Name
        $lines.Add("- [$display]($relativeFromHub)")
    }

    $lines.Add('')
}

Set-Content -Path $resolvedOutputFile -Value $lines -Encoding UTF8

Write-Host "GENERATED: $resolvedOutputFile"
