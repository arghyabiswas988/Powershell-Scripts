# ==================================================
# Windows 11 - Clean Taskbar
# ==================================================

Write-Host "Configuring taskbar settings..."

# Start menu alignment
New-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "TaskbarAl" `
    -PropertyType DWord `
    -Value 0 `
    -Force | Out-Null

# Hide Search
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Force | Out-Null
Set-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
    -Name "SearchboxTaskbarMode" `
    -Value 0

# Hide Task View
Set-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "ShowTaskViewButton" `
    -Value 0 `
    -Force

# Hide Widgets
Set-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "TaskbarDa" `
    -Value 0 `
    -Force

# Hide Chat / Teams
Set-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "TaskbarMn" `
    -Value 0 `
    -Force

# Hide Copilot (supported builds)
New-Item `
    -Path "HKCU:\Software\Microsoft\Windows\Shell\Copilot\BingChat" `
    -Force | Out-Null

Set-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\Shell\Copilot\BingChat" `
    -Name "IsUserEligible" `
    -Value 0 `
    -Force

Write-Host "Removing pinned taskbar applications..."

# Stop Explorer
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Start-Sleep -Seconds 2

# Remove taskbar pinned items
$TaskbandKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband"

if (Test-Path $TaskbandKey) {
    Remove-ItemProperty `
        -Path $TaskbandKey `
        -Name Favorites `
        -ErrorAction SilentlyContinue

    Remove-ItemProperty `
        -Path $TaskbandKey `
        -Name FavoritesResolve `
        -ErrorAction SilentlyContinue
}

# Remove pinned taskbar shortcuts
$PinnedPath = Join-Path `
    $env:APPDATA `
    "Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

if (Test-Path $PinnedPath) {
    Remove-Item `
        -Path "$PinnedPath\*" `
        -Force `
        -Recurse `
        -ErrorAction SilentlyContinue
}

Write-Host "Restarting Explorer..."

Start-Process explorer.exe

Write-Host ""
Write-Host "========================================"
Write-Host "Taskbar cleanup completed"
Write-Host "========================================"
Write-Host "Start menu aligned left"
Write-Host "Search hidden"
Write-Host "Task View hidden"
Write-Host "Widgets hidden"
Write-Host "Chat hidden"
Write-Host "Copilot hidden"
Write-Host "Pinned taskbar apps removed"
Write-Host ""
