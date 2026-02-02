$path = "c:\Users\plain\SmartLedger\lib\screens\food_expiry_main_screen.dart"
$content = Get-Content $path -Encoding UTF8
$part1 = $content[0..1008]
$part2 = $content[2347..($content.Count-1)]
$newContent = $part1 + $part2
$newContent | Set-Content $path -Encoding UTF8
Write-Host "Lines removed safely."