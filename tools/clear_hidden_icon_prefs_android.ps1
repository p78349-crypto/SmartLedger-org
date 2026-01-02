param(
  # Android applicationId (package name). If omitted, script tries to read it from android/app/build.gradle.kts.
  [string]$Package = "",

  # If provided, use this adb executable (e.g. "C:\\Android\\platform-tools\\adb.exe").
  [string]$Adb = "adb",

  # When set, prints which keys would be removed but does not write back.
  [switch]$DryRun,

  # When set, prints the matched keys to stdout.
  [switch]$ListKeys
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-PackageFromGradleKts {
  param([string]$RepoRoot)

  $gradlePath = Join-Path $RepoRoot 'android/app/build.gradle.kts'
  if (-not (Test-Path $gradlePath)) {
    throw "Could not find $gradlePath. Pass -Package explicitly."
  }

  $text = Get-Content -Raw -Path $gradlePath

  # Typical: applicationId = "com.example.app"
  $m = [regex]::Match($text, 'applicationId\s*=\s*"([^"]+)"')
  if ($m.Success) { return $m.Groups[1].Value }

  # Fallback: applicationId("com.example.app")
  $m2 = [regex]::Match($text, 'applicationId\s*\(\s*"([^"]+)"\s*\)')
  if ($m2.Success) { return $m2.Groups[1].Value }

  throw "Failed to parse applicationId from $gradlePath. Pass -Package explicitly."
}

function Assert-Adb {
  param([string]$AdbExe)
  $cmd = Get-Command $AdbExe -ErrorAction SilentlyContinue
  if ($cmd) {
    return $cmd.Source
  }

  # Try common Windows SDK locations.
  $candidates = New-Object System.Collections.Generic.List[string]

  $sdkRoot = $env:ANDROID_SDK_ROOT
  if ([string]::IsNullOrWhiteSpace($sdkRoot)) { $sdkRoot = $env:ANDROID_HOME }
  if (-not [string]::IsNullOrWhiteSpace($sdkRoot)) {
    $candidates.Add((Join-Path $sdkRoot 'platform-tools\adb.exe')) | Out-Null
  }

  if ($env:LOCALAPPDATA) {
    $candidates.Add((Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe')) | Out-Null
  }

  # Known common fallback (older setups)
  $candidates.Add('C:\Android\platform-tools\adb.exe') | Out-Null

  foreach ($p in $candidates) {
    if (Test-Path $p) {
      return $p
    }
  }

  $hint = if ($env:LOCALAPPDATA) {
    (Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe')
  } else {
    '<LOCALAPPDATA>\Android\Sdk\platform-tools\adb.exe'
  }

  throw "adb not found. Add adb to PATH or pass -Adb '$hint'"
}

function Get-FlutterSharedPreferencesXml {
  param(
    [string]$AdbExe,
    [string]$PackageName
  )

  # Using run-as requires a debug build installed for this package.
  # We read the file via exec-out to avoid Windows newline issues.
  $args = @(
    'exec-out',
    'run-as',
    $PackageName,
    'cat',
    'shared_prefs/FlutterSharedPreferences.xml'
  )

  $out = & $AdbExe @args 2>$null
  if (-not $out -or $out.Trim().Length -eq 0) {
    throw "Failed to read FlutterSharedPreferences.xml via run-as. Ensure a debug build is installed and package name is correct: $PackageName"
  }
  return $out
}

function Save-FlutterSharedPreferencesXml {
  param(
    [string]$AdbExe,
    [string]$PackageName,
    [string]$XmlText
  )

  # Write back using stdin redirection inside app sandbox.
  # Note: We avoid escaping issues by using: sh -c 'cat > ...'
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $AdbExe
  $psi.Arguments = "shell run-as $PackageName sh -c `"cat > shared_prefs/FlutterSharedPreferences.xml`""
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false

  $p = New-Object System.Diagnostics.Process
  $p.StartInfo = $psi
  [void]$p.Start()

  $p.StandardInput.Write($XmlText)
  $p.StandardInput.Close()

  $stdout = $p.StandardOutput.ReadToEnd()
  $stderr = $p.StandardError.ReadToEnd()
  $p.WaitForExit()

  if ($p.ExitCode -ne 0) {
    throw "Failed to write FlutterSharedPreferences.xml (exit=$($p.ExitCode)). stderr: $stderr"
  }

  # Best-effort: stop the app so next launch reloads prefs.
  & $AdbExe shell am force-stop $PackageName | Out-Null
}

function Remove-HiddenIconPreferenceNodes {
  param(
    [xml]$Doc
  )

  # Keys created by UserPrefService:
  # - <account>_page_<idx>_hidden_icons(_<profileKey>)
  # - <account>_page_<idx>_hidden_origins(_<profileKey>)
  # - <account>_page_<idx>_icon_restore_behavior
  # - <account>_pageId_<pageId>_hidden_icons
  # - <account>_pageId_<pageId>_hidden_origins
  # - <account>_pageId_<pageId>_icon_restore_behavior
  #
  # On Android, shared_preferences often stores keys prefixed with "flutter.".

  $patterns = @(
    # legacy pageIndex-based
    '^(flutter\.)?.+_page_\d+_hidden_icons(_[^\s]+)?$',
    '^(flutter\.)?.+_page_\d+_hidden_origins(_[^\s]+)?$',
    '^(flutter\.)?.+_page_\d+_icon_restore_behavior$',

    # pageId-based
    '^(flutter\.)?.+_pageId_.+_hidden_icons$',
    '^(flutter\.)?.+_pageId_.+_hidden_origins$',
    '^(flutter\.)?.+_pageId_.+_icon_restore_behavior$'
  )

  $removed = New-Object System.Collections.Generic.List[string]

  # SharedPreferences XML is typically: <map> ... children with attribute name="..." ... </map>
  $map = $Doc.SelectSingleNode('/map')
  if (-not $map) {
    throw 'Unexpected XML: root node is not <map>.'
  }

  # Collect first, then remove (safe iteration).
  $toRemove = @()
  foreach ($node in @($map.ChildNodes)) {
    if (-not $node.Attributes) { continue }
    $nameAttr = $node.Attributes['name']
    if (-not $nameAttr) { continue }
    $keyName = [string]$nameAttr.Value

    foreach ($pat in $patterns) {
      if ([regex]::IsMatch($keyName, $pat)) {
        $toRemove += $node
        $removed.Add($keyName) | Out-Null
        break
      }
    }
  }

  foreach ($n in $toRemove) {
    [void]$map.RemoveChild($n)
  }

  return ,$removed
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

$Adb = Assert-Adb -AdbExe $Adb

if ([string]::IsNullOrWhiteSpace($Package)) {
  $Package = Get-PackageFromGradleKts -RepoRoot $repoRoot
}

Write-Host "[clear_hidden_icon_prefs_android] adb: $Adb" -ForegroundColor Cyan
Write-Host "[clear_hidden_icon_prefs_android] Package: $Package" -ForegroundColor Cyan
Write-Host "[clear_hidden_icon_prefs_android] Mode: $([string]::Join(', ', @(
  $(if ($DryRun) { 'DryRun' } else { 'Write' }),
  $(if ($ListKeys) { 'ListKeys' } else { 'NoList' })
).Where({ $_ -ne $null })))" -ForegroundColor Cyan

$xmlText = Get-FlutterSharedPreferencesXml -AdbExe $Adb -PackageName $Package

[xml]$doc = $xmlText
$removedKeys = Remove-HiddenIconPreferenceNodes -Doc $doc

if ($ListKeys) {
  if ($removedKeys.Count -eq 0) {
    Write-Host "No matching hidden-icon keys found." -ForegroundColor Yellow
  } else {
    Write-Host "Matched keys ($($removedKeys.Count)):" -ForegroundColor Yellow
    $removedKeys | Sort-Object -Unique | ForEach-Object { Write-Host " - $_" }
  }
}

if ($DryRun) {
  Write-Host "DryRun: not writing changes. Would remove $($removedKeys.Count) keys." -ForegroundColor Yellow
  exit 0
}

if ($removedKeys.Count -eq 0) {
  Write-Host "No matching hidden-icon keys found. Nothing to write." -ForegroundColor Green
  exit 0
}

# Preserve XML declaration + formatting best-effort.
$sw = New-Object System.IO.StringWriter
$doc.Save($sw)
$updated = $sw.ToString()

Save-FlutterSharedPreferencesXml -AdbExe $Adb -PackageName $Package -XmlText $updated

Write-Host "Removed $($removedKeys.Count) hidden-icon keys and wrote updated FlutterSharedPreferences.xml" -ForegroundColor Green
