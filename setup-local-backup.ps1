# Setup Local Backup Task Scheduler
# Run every 3 hours automatically
# Created: 2025-01-03

param(
    [ValidateSet('enable', 'disable', 'status')]
    [string]$Action = 'status',
    [int]$Interval = 3
)

$TaskName = "SmartLedger-Local-Backup"
$ScriptPath = "C:\Users\plain\SmartLedger\local-backup-scheduler.ps1"
$ProjectRoot = "C:\Users\plain\SmartLedger"

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "SmartLedger Local Backup Task Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

function Enable-LocalBackupTask {
    Write-Host "Creating scheduled task..." -ForegroundColor Green
    
    $Action = New-ScheduledTaskAction `
        -Execute "powershell.exe" `
        -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
    
    $Trigger = New-ScheduledTaskTrigger `
        -Once `
        -At (Get-Date) `
        -RepetitionInterval (New-TimeSpan -Hours $Interval) `
        -RepetitionDuration (New-TimeSpan -Days 365)
    
    $Settings = New-ScheduledTaskSettingsSet `
        -AllowStartIfOnBatteries `
        -DontStopIfGoingOnBatteries
    
    $Principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType ServiceAccount
    
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $Action `
        -Trigger $Trigger `
        -Settings $Settings `
        -Principal $Principal `
        -Force | Out-Null
    
    Write-Host "Task created: $TaskName" -ForegroundColor Green
    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor Yellow
    Write-Host "  Interval: Every $Interval hours" -ForegroundColor White
    Write-Host "  Script: $ScriptPath" -ForegroundColor White
    Write-Host "  Log: $ProjectRoot\local-backup.log" -ForegroundColor White
}

function Disable-LocalBackupTask {
    Write-Host "Removing scheduled task..." -ForegroundColor Yellow
    
    try {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction Stop
        Write-Host "Task removed: $TaskName" -ForegroundColor Green
    } catch {
        if ($_ -match "not found") {
            Write-Host "Task not found: $TaskName" -ForegroundColor Yellow
        } else {
            Write-Host "Error removing task: $_" -ForegroundColor Red
        }
    }
}

function Show-TaskStatus {
    Write-Host "Checking task status..." -ForegroundColor Cyan
    
    $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($Task) {
        Write-Host ""
        Write-Host "Task: $($Task.TaskName)" -ForegroundColor Green
        Write-Host "Status: $($Task.State)" -ForegroundColor White
        Write-Host ""
        
        $TaskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
        Write-Host "Last Run: $($TaskInfo.LastRunTime)" -ForegroundColor White
        Write-Host "Next Run: $($TaskInfo.NextRunTime)" -ForegroundColor White
        
        # Show log preview
        if (Test-Path "$ProjectRoot\local-backup.log") {
            Write-Host ""
            Write-Host "Recent Log:" -ForegroundColor Yellow
            Get-Content "$ProjectRoot\local-backup.log" | Select-Object -Last 5 | ForEach-Object {
                Write-Host "  $_" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host ""
        Write-Host "Status: DISABLED" -ForegroundColor Red
        Write-Host "Task not found: $TaskName" -ForegroundColor Yellow
    }
}

function Show-Usage {
    Write-Host ""
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  powershell -File setup-local-backup.ps1 -Action enable -Interval 3" -ForegroundColor White
    Write-Host "  powershell -File setup-local-backup.ps1 -Action disable" -ForegroundColor White
    Write-Host "  powershell -File setup-local-backup.ps1 -Action status" -ForegroundColor White
}

# Main execution
switch ($Action) {
    'enable' {
        Enable-LocalBackupTask
        Show-Usage
    }
    'disable' {
        Disable-LocalBackupTask
        Show-Usage
    }
    'status' {
        Show-TaskStatus
        Show-Usage
    }
}

Write-Host ""
