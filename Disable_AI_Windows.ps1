<#
.SYNOPSIS
    Disables Windows Copilot, Edge AI features, Windows AI components, Notepad AI, Paint AI, and removes Copilot provisioned packages.

.DESCRIPTION
    This script configures multiple registry policies to disable AI-related features across Windows, Edge, Notepad, and Paint.
    It also removes Copilot Appx provisioned packages from the system.

.AUTHOR
    Arghya Biswas

.NOTES
    Script auto-elevates if not run as Administrator.
#>

# ===============================
# Auto Elevation
# ===============================
$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator"
)

if (-not $IsAdmin) {
    Write-Host "Relaunching script as Administrator..." -ForegroundColor Yellow

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.Verb = "runas"

    try {
        [System.Diagnostics.Process]::Start($psi) | Out-Null
    }
    catch {
        Write-Host "User cancelled elevation prompt." -ForegroundColor Red
        exit 1
    }

    exit 0
}

Write-Host "===== Starting Configuration =====" -ForegroundColor Cyan

function Set-RegistryValue {
    param (
        [string]$Path,
        [string]$Name,
        [int]$Value
    )

    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }

        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType DWord -Force | Out-Null
        Write-Host "[OK] Set $Name = $Value at $Path" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to set $Name at $Path : $_" -ForegroundColor Red
    }
}

# ===============================
# Windows Copilot
# ===============================
Set-RegistryValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" `
                  -Name "TurnOffWindowsCopilot" -Value 1

# ===============================
# Microsoft Edge Policies
# ===============================
$edgePath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"

Set-RegistryValue -Path $edgePath -Name "HubsSidebarEnabled" -Value 0
Set-RegistryValue -Path $edgePath -Name "ComposeInlineEnabled" -Value 0
Set-RegistryValue -Path $edgePath -Name "EdgeHistoryAISearchEnabled" -Value 0

# ===============================
# WSAIFabric Service
# ===============================
Set-RegistryValue -Path "HKLM:\SYSTEM\CurrentControlSet\Services\WSAIFabricSvc" `
                  -Name "Start" -Value 3

# ===============================
# Paint AI Features (Defender Policy Path)
# ===============================
$paintPolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Paint"

Set-RegistryValue -Path $paintPolicyPath -Name "DisableCocreator" -Value 1
Set-RegistryValue -Path $paintPolicyPath -Name "DisableGenerativeFill" -Value 1
Set-RegistryValue -Path $paintPolicyPath -Name "DisableAIFeature" -Value 1

# ===============================
# Paint AI Features (CurrentVersion Policy Path)
# ===============================
$paintCurrentPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Paint"

Set-RegistryValue -Path $paintCurrentPath -Name "DisableCocreator" -Value 1
Set-RegistryValue -Path $paintCurrentPath -Name "DisableGenerativeFill" -Value 1
Set-RegistryValue -Path $paintCurrentPath -Name "DisableImageCreator" -Value 1

# ===============================
# Windows AI Settings
# ===============================
$aiPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI"

Set-RegistryValue -Path $aiPath -Name "AllowRecallEnablement" -Value 0
Set-RegistryValue -Path $aiPath -Name "AllowRecallExport" -Value 0
Set-RegistryValue -Path $aiPath -Name "DisableAIDataAnalysis" -Value 1
Set-RegistryValue -Path $aiPath -Name "DisableSettingsAgent" -Value 1
Set-RegistryValue -Path $aiPath -Name "RemoveMicrosoftCopilotApp" -Value 1

# ===============================
# Notepad AI Features
# ===============================
$notepadPath = "HKLM:\SOFTWARE\Policies\WindowsNotepad"

Set-RegistryValue -Path $notepadPath -Name "DisableAIFeatures" -Value 1

# ===============================
# Remove Copilot Provisioned Package
# ===============================
Write-Host "Removing Copilot provisioned packages..." -ForegroundColor Yellow

try {
    $packages = Get-AppxProvisionedPackage -Online | Where-Object {
        $_.DisplayName -match "copilot"
    }

    foreach ($pkg in $packages) {
        Write-Host "Removing: $($pkg.DisplayName)"
        Remove-AppxProvisionedPackage -Online -PackageName $pkg.PackageName -ErrorAction Stop | Out-Null
    }

    Write-Host "[OK] Copilot packages removed." -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Failed to remove Copilot packages: $_" -ForegroundColor Red
}

Write-Host "===== Completed =====" -ForegroundColor Cyan
Write-Host "NOTE: Restart the computer for all changes to take effect." -ForegroundColor Yellow
