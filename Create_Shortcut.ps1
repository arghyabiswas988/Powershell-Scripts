<#
.SYNOPSIS
Keep system awake by pressing SCROLLLOCK and create helper shortcuts.

.DESCRIPTION
Creates:
- Keep-Alive PowerShell script
- Keep-Alive Start Menu shortcut
- RunAs batch script
- RunAs desktop shortcut
- Restart desktop shortcut

.AUTHOR
Arghya Biswas
#>

# ==================================================
# Create Main Folder
# ==================================================

$Folder = "C:\Temp\Keep-Alive"

If (!(Test-Path $Folder)) {
    Write-Host "Creating Temp folder..."
    New-Item -Path $Folder -ItemType Directory -Force | Out-Null
}

# ==================================================
# Configure Folder Icon
# ==================================================

$DesktopIni = @"
[.ShellClassInfo]
IconResource=C:\WINDOWS\System32\SHELL32.dll,41
"@

$TargetDirectory = $Folder

# Create desktop.ini
Add-Content "$($TargetDirectory)\desktop.ini" -Value $DesktopIni

# Set desktop.ini attributes
(Get-Item "$($TargetDirectory)\desktop.ini" -Force).Attributes = 'Hidden, System, Archive'

# Set folder attributes
(Get-Item $TargetDirectory -Force).Attributes = 'ReadOnly, Directory'

# ==================================================
# Create Keep-Alive PowerShell Script
# ==================================================

Write-Host "Writing Keep-Alive scripts..."

$PSScript = Join-Path $Folder "Keep-Alive.ps1"

Write-Host "Creating Keep-Alive PowerShell script..."

New-Item -Path $PSScript -ItemType File -Force | Out-Null

$PSScriptContent = @'
$wsh = New-Object -ComObject WScript.Shell

while ($true) {
    $wsh.SendKeys('+{SCROLLLOCK}')
    Start-Sleep -Seconds 59
}
'@

Write-Host "Writing content to Keep-Alive script..."

$PSScriptContent | Out-File -FilePath $PSScript -Encoding UTF8 -Force

# ==================================================
# Create Keep-Alive Start Menu Shortcut
# ==================================================

Write-Host "Creating Keep-Alive Start Menu shortcut..."

$SourceFilePath = "powershell.exe"

$StartMenuPrograms = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs"
$ShortcutPath = Join-Path $StartMenuPrograms "Keep-Alive.lnk"

$WScriptObj = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptObj.CreateShortcut($ShortcutPath)

$Shortcut.TargetPath = $SourceFilePath
$Shortcut.WorkingDirectory = $env:USERPROFILE
$Shortcut.Arguments = "-ExecutionPolicy Bypass -WindowStyle Minimized -File ""$PSScript"""
$Shortcut.WindowStyle = 2
$Shortcut.Description = "Keep your system active."
$Shortcut.IconLocation = "shell32.dll,41"

$Shortcut.Save()

# ==================================================
# Create RunAs Folder
# ==================================================

Write-Host "Creating RunAs folder..."

$RunAsFolder = "C:\Temp\RunAs"

If (!(Test-Path $RunAsFolder)) {
    New-Item -Path $RunAsFolder -ItemType Directory -Force | Out-Null
}

# ==================================================
# Create RunAs Batch Script
# ==================================================

Write-Host "Creating RunAs batch script..."

$RunAsBat = Join-Path $RunAsFolder "RunAs.bat"

$RunAsContent = @'
@echo off

:: ===============================
:: Check for Administrator rights
:: ===============================

net session >nul 2>&1

if %errorLevel% neq 0 (
    echo Requesting administrator privileges...

    powershell -NoProfile -ExecutionPolicy Bypass ^
        -Command "Start-Process '%~f0' -Verb RunAs"

    exit /b
)

echo Running with elevated privileges!
echo.

:: ==================================
:: Place ADMIN commands below
:: ==================================

start cmd
'@

$RunAsContent | Out-File -FilePath $RunAsBat -Encoding ASCII -Force

# ==================================================
# Create RunAs Desktop Shortcut
# ==================================================

Write-Host "Creating RunAs desktop shortcut..."

$RunAsShortcutPath = Join-Path "$env:USERPROFILE\Desktop" "RunAs.lnk"

$RunAsShortcut = $WScriptObj.CreateShortcut($RunAsShortcutPath)

$RunAsShortcut.TargetPath = $RunAsBat
$RunAsShortcut.WorkingDirectory = $RunAsFolder
$RunAsShortcut.WindowStyle = 1
$RunAsShortcut.Description = "Run commands as Administrator"
$RunAsShortcut.IconLocation = "shell32.dll,21"

$RunAsShortcut.Save()

# ==================================================
# Create Restart Desktop Shortcut
# ==================================================

Write-Host "Creating Restart desktop shortcut..."

$RestartShortcutPath = Join-Path "$env:USERPROFILE\Desktop" "Restart.lnk"

$RestartShortcut = $WScriptObj.CreateShortcut($RestartShortcutPath)

$RestartShortcut.TargetPath = "shutdown.exe"
$RestartShortcut.Arguments = "-r -f -t 0"
$RestartShortcut.WorkingDirectory = "$env:SystemRoot\System32"
$RestartShortcut.WindowStyle = 1
$RestartShortcut.Description = "Restart the computer immediately"
$RestartShortcut.IconLocation = "shell32.dll,238"

$RestartShortcut.Save()

# ==================================================
# Restore Classic Windows 11 Right-Click Menu
# ==================================================

Write-Host "Enabling classic Windows 11 context menu..."

reg.exe add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /f /ve | Out-Null

Write-Host "Restarting Explorer..."

Get-Process explorer -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 2
Start-Process explorer.exe

Write-Host "Classic Windows 11 context menu enabled."

# ==================================================
# Completed
# ==================================================

Write-Host ""
Write-Host "========================================"
Write-Host "Setup completed successfully."
Write-Host "========================================"
Write-Host ""
Write-Host "Created:"
Write-Host " - Keep-Alive shortcut in Start Menu Programs"
Write-Host " - RunAs shortcut on Desktop"
Write-Host " - Restart shortcut on Desktop"
Write-Host ""
Write-Host "Configured:"
Write-Host " - Classic Windows 11 context menu enabled"
Write-Host ""
