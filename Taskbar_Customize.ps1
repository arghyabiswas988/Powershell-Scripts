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
# ==================================================
# Hide Search (Windows 11 24H2/25H2)
# ==================================================

Write-Host "Hiding Search..."

# User preference
New-Item `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
    -Force | Out-Null

New-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
    -Name "SearchboxTaskbarMode" `
    -PropertyType DWord `
    -Value 0 `
    -Force | Out-Null

New-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" `
    -Name "SearchboxTaskbarModeCache" `
    -PropertyType DWord `
    -Value 1 `
    -Force | Out-Null

# Policy-based enforcement
New-Item `
    -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" `
    -Force | Out-Null

New-ItemProperty `
    -Path "HKCU:\Software\Policies\Microsoft\Windows\Explorer" `
    -Name "DisableSearchBoxSuggestions" `
    -PropertyType DWord `
    -Value 1 `
    -Force | Out-Null

# Hide Task View
Set-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "ShowTaskViewButton" `
    -Value 0 `
    -Force

# ==================================================
# Disable Widgets (HKCU Only)
# ==================================================

Write-Host "Disabling Widgets..."

New-Item `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Force | Out-Null

# Hide Widgets button
New-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
    -Name "TaskbarDa" `
    -PropertyType DWord `
    -Value 0 `
    -Force | Out-Null

# Additional Windows 11 builds
New-Item `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Dsh" `
    -Force | Out-Null

New-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Dsh" `
    -Name "IsPrelaunchEnabled" `
    -PropertyType DWord `
    -Value 0 `
    -Force | Out-Null

New-ItemProperty `
    -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Dsh" `
    -Name "IsWidgetsAvailable" `
    -PropertyType DWord `
    -Value 0 `
    -Force | Out-Null

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

Write-Host "Restarting Explorer..."

Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
Start-Process explorer.exe

# Refresh shell
rundll32.exe user32.dll,UpdatePerUserSystemParameters

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
