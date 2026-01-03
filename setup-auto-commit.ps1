# Setup Auto Commit Task Scheduler
# Run every 2 hours automatically
# Created: 2025-01-03

param(
    [ValidateSet('enable', 'disable', 'status')]
    [string]$Action = 'status',
    [int]$Interval = 4
)

$TaskName = "SmartLedger-Auto-Commit"
$ScriptPath = "C:\Users\plain\SmartLedger\auto-commit-scheduler.ps1"
$ProjectRoot = "C:\Users\plain\SmartLedger"

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "SmartLedger Auto-Commit Task Setup" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

function Enable-AutoCommitTask {
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
    Write-Host "  Log: $ProjectRoot\auto-commit.log" -ForegroundColor White
}

function Disable-AutoCommitTask {
    Write-Host "Removing scheduled task..." -ForegroundColor Yellow
    
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false -ErrorAction SilentlyContinue
    
    Write-Host "Task removed: $TaskName" -ForegroundColor Yellow
}

function Show-TaskStatus {
    Write-Host "Checking task status..." -ForegroundColor Cyan
    Write-Host ""
    
    $Task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    
    if ($Task) {
        Write-Host "Status: ENABLED" -ForegroundColor Green
        Write-Host ""
        Write-Host "Task Details:" -ForegroundColor Yellow
        Write-Host "  Name: $($Task.TaskName)" -ForegroundColor White
        Write-Host "  State: $($Task.State)" -ForegroundColor White
        
        $TaskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
        Write-Host "  Last Run: $($TaskInfo.LastRunTime)" -ForegroundColor White
        Write-Host "  Last Result: $($TaskInfo.LastTaskResult)" -ForegroundColor White
        Write-Host "  Next Run: $($TaskInfo.NextRunTime)" -ForegroundColor White
        
        Write-Host ""
        Write-Host "Log File:" -ForegroundColor Yellow
        $LogFile = Join-Path $ProjectRoot "auto-commit.log"
        if (Test-Path $LogFile) {
            Write-Host "  Location: $LogFile" -ForegroundColor White
            $LastLines = Get-Content $LogFile -Tail 5
            Write-Host "  Last entries:" -ForegroundColor White
            foreach ($Line in $LastLines) {
                Write-Host "    $Line" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "Status: DISABLED" -ForegroundColor Red
        Write-Host "Task not found: $TaskName" -ForegroundColor Yellow
    }
}

switch ($Action) {
    'enable' {
        Enable-AutoCommitTask
    }
    'disable' {
        Disable-AutoCommitTask
    }
    'status' {
        Show-TaskStatus
    }
}

Write-Host ""
Write-Host "Usage:" -ForegroundColor Cyan
Write-Host "  powershell -File setup-auto-commit.ps1 -Action enable" -ForegroundColor White
Write-Host "  powershell -File setup-auto-commit.ps1 -Action disable" -ForegroundColor White
Write-Host "  powershell -File setup-auto-commit.ps1 -Action status" -ForegroundColor White
Write-Host ""
