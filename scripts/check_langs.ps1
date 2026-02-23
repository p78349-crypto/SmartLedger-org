$files = Get-ChildItem -Path 'lib/services/recipe_service_default_recipes_*.dart'
$langs = @('ko','en','es','fr','hi','it','ja','pl','pt','ru','de','ar','el','nl','sv','th','tr','vi')
foreach ($f in $files) {
  $text = Get-Content $f.FullName -Raw
  $missing = @()
  foreach ($l in $langs) {
    if ($text -notmatch "'$l'\s*:\s*") { $missing += $l }
  }
  if ($missing.Count -eq 0) { Write-Output "$($f.Name): OK" } else { Write-Output "$($f.Name): MISSING -> $($missing -join ',')" }
}
