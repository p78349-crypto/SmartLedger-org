#!/usr/bin/env powershell
# Japan MEXT Excel to CSV Converter
# SmartLedger Phase 3 Data Preparation
# Purpose: Convert MEXT Excel files to CSV format for import

param(
    [string]$SourceDir = "C:\Users\plain\GemmaFineTuning\archive\korean_reference\글로벌 식료품 데이터",
    [string]$OutputDir = "C:\Users\plain\SmartLedger\data\japan_csv"
)

Write-Host "`n╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   Japan MEXT Excel → CSV Converter                        ║" -ForegroundColor Cyan
Write-Host "║   SmartLedger Phase 3 Data Preparation                    ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Check source directory
if (-not (Test-Path $SourceDir)) {
    Write-Host "❌ Source directory not found: $SourceDir" -ForegroundColor Red
    exit 1
}

# Create output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    Write-Host "✓ Output directory created: $OutputDir`n" -ForegroundColor Green
}

# Find MEXT Excel files
$excelFiles = Get-ChildItem -Path $SourceDir -Filter "*mxt*.xlsx" -ErrorAction SilentlyContinue
$count = $excelFiles.Count

Write-Host "🔍 Found Excel files: $count`n" -ForegroundColor Yellow

if ($count -eq 0) {
    Write-Host "⚠️  No MEXT Excel files found!" -ForegroundColor Yellow
    exit 0
}

# Excel application object
$excel = $null
$converted = 0
$failed = 0

try {
    # Get Excel COM object
    $excel = New-Object -ComObject Excel.Application
    $excel.Visible = $false
    $excel.DisplayAlerts = $false

    Write-Host "📋 Converting files...`n" -ForegroundColor Cyan

    foreach ($file in $excelFiles) {
        $fileName = $file.Name
        $csvFileName = $fileName -replace '\.xlsx$', '.csv'
        $outputPath = Join-Path $OutputDir $csvFileName

        Write-Host "  Processing: $fileName" -ForegroundColor White

        try {
            # Open Excel file
            $workbook = $excel.Workbooks.Open($file.FullName)
            $worksheet = $workbook.Worksheets.Item(1)  # First sheet

            # Get data range
            $usedRange = $worksheet.UsedRange
            $rows = $usedRange.Rows.Count
            $cols = $usedRange.Columns.Count

            Write-Host "    └─ Rows: $rows, Columns: $cols" -ForegroundColor Gray

            # Save as CSV
            $workbook.SaveAs($outputPath, 6)  # 6 = CSV format in Excel
            Write-Host "    ✓ Converted to: $(Split-Path -Leaf $outputPath)" -ForegroundColor Green
            $converted++

            # Close workbook
            $workbook.Close($false)
        }
        catch {
            Write-Host "    ❌ Error: $($_.Exception.Message)" -ForegroundColor Red
            $failed++
        }
    }
}
catch {
    Write-Host "❌ Excel error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    # Cleanup
    if ($excel) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
        [GC]::Collect()
    }
}

# Summary
Write-Host "`n═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "📊 Conversion Summary:" -ForegroundColor Yellow
Write-Host "  ✓ Converted: $converted files" -ForegroundColor Green
Write-Host "  ❌ Failed: $failed files" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host "  📍 Output: $OutputDir" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

# List output files
if ($converted -gt 0) {
    Write-Host "📁 Generated CSV files:" -ForegroundColor Cyan
    Get-ChildItem -Path $OutputDir -Filter "*.csv" | ForEach-Object {
        $sizeMB = [math]::Round($_.Length / 1MB, 2)
        Write-Host "  ✓ $($_.Name) ($sizeMB MB)" -ForegroundColor White
    }
}
else {
    Write-Host "⚠️  No CSV files generated!" -ForegroundColor Yellow
}

Write-Host "`n✅ Conversion complete!`n" -ForegroundColor Green
