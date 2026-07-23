# Requires PowerShell Administrator Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator! Please restart PowerShell as Administrator."
    Exit
}

# Optional: Log file path (Uncomment to log output to a file)
# $LogFilePath = "$env:SystemDrive\CleanupLog.txt"

# Helper function for timestamped logging
function Write-Log {
    param (
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $FormattedMessage = "[$Timestamp] $Message"
    
    Write-Host $FormattedMessage -ForegroundColor $Color

    if ($LogFilePath) {
        Add-Content -Path $LogFilePath -Value $FormattedMessage -ErrorAction SilentlyContinue
    }
}

Write-Log "========================================" -Color Cyan
Write-Log "Starting Advanced System Cleanup Routine" -Color Cyan
Write-Log "========================================" -Color Cyan

# 1. User & System Temp Folders
Write-Log "Cleaning User & System Temporary files..." -Color Green
$TempFolders = @(
    "$env:TEMP",
    "$env:SystemRoot\Temp",
    "$env:SystemDrive\Users\*\AppData\Local\Temp"
)

foreach ($folder in $TempFolders) {
    Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue | 
        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
}

# 2. Clear Memory Dumps & Crash Logs
Write-Log "Clearing Memory Dumps & System Diagnostics..." -Color Green
Remove-Item -Path "$env:SystemRoot\MEMORY.DMP" -Force -ErrorAction SilentlyContinue
Remove-Item -Path "$env:SystemRoot\Minidump\*" -Force -ErrorAction SilentlyContinue

# 3. System Prefetch
Write-Log "Clearing Windows Prefetch files..." -Color Green
Remove-Item -Path "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

# 4. Windows Update Cache
Write-Log "Checking Windows Update service status..." -Color Yellow
$service = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
$wasRunning = ($service -and $service.Status -eq "Running")

if ($wasRunning) {
    Write-Log "Stopping Windows Update service..." -Color Yellow
    Stop-Service -Name wuauserv -Force -NoWait -ErrorAction SilentlyContinue
    
    # Wait up to 10 seconds for service to stop gracefully
    $timeout = 10
    while ((Get-Service -Name wuauserv).Status -ne "Stopped" -and $timeout -gt 0) {
        Start-Sleep -Seconds 1
        $timeout--
    }
} else {
    Write-Log "Windows Update service is not running." -Color Green
}

Write-Log "Cleaning Windows Update Cache..." -Color Green
Remove-Item -Path "$env:SystemRoot\SoftwareDistribution\Download\*" -Force -Recurse -ErrorAction SilentlyContinue

if ($wasRunning) {
    Write-Log "Restarting Windows Update service..." -Color Yellow
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
}

# 5. Configure & Run Windows Disk Cleanup (Cleanmgr)
Write-Log "Enabling default flags for Disk Cleanup..." -Color Yellow
$StateFlagsKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
$CleanupItems = @("Temporary Files", "Setup Log Files", "Old Chkdsk Files", "Recycle Bin", "Memory Dump Files")

foreach ($item in $CleanupItems) {
    $itemKey = "$StateFlagsKey\$item"
    if (Test-Path $itemKey) {
        Set-ItemProperty -Path $itemKey -Name "StateFlags0001" -Value 2 -ErrorAction SilentlyContinue
    }
}

Write-Log "Running Disk Cleanup Tool..." -Color Green
Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:1" -Wait -WindowStyle Hidden

# 6. PowerShell Process Memory Release
Write-Log "Releasing process memory..." -Color Green
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

# 7. DISM Component Store Analysis & Cleanup
Write-Log "Analyzing Windows Component Store (WinSxS)..." -Color Yellow
$analysisRaw = DISM /Online /Cleanup-Image /AnalyzeComponentStore

if ($analysisRaw -match "Component Store Cleanup Recommended : Yes" -or $analysisRaw -match "Cleanup Recommended") {
    Write-Log "Cleanup recommended. Executing DISM Component Cleanup (This may take a few minutes)..." -Color Green
    DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase
} else {
    Write-Log "No component cleanup required at this time." -Color Green
}

Write-Log "========================================" -Color Cyan
Write-Log "Optimization Complete! Reboot Recommended." -Color Cyan
Write-Log "========================================" -Color Cyan
