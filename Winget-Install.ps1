<#
.SYNOPSIS
    Installs Google Chrome (or any app) using Winget in the SYSTEM context.

.DESCRIPTION
    Designed for deployment via Intune/SCCM/RMM. It locates the Winget executable 
    within the protected WindowsApps folder (accessible by SYSTEM) and enforces 
    a machine-wide installation.
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$AppId = "Google.Chrome",

    [Parameter(Mandatory=$false)]
    [string]$LogPath = "C:\Temp\WingetInstall_Chrome_System.log"
)

# -----------------------------------------------------------------------------
# Helper Function: Logging
# -----------------------------------------------------------------------------
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $logEntry = "[$timestamp] [$Level] $Message"
    
    Write-Host $logEntry
    
    $logDir = Split-Path $LogPath
    if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
    Add-Content -Path $LogPath -Value $logEntry
}

try {
    Write-Log "Starting SYSTEM context Winget installation for: $AppId" "INFO"

    # 1. Locate Winget for the SYSTEM account
    $wingetPath = $null
    
    # SYSTEM account can read Program Files\WindowsApps. We look for the DesktopAppInstaller folder.
    $windowsAppsPath = "$env:ProgramFiles\WindowsApps"
    $appInstallerPattern = "Microsoft.DesktopAppInstaller_*_x64__8wekyb3d8bbwe"
    
    Write-Log "Searching for Winget in $windowsAppsPath..." "INFO"
    
    if (Test-Path $windowsAppsPath) {
        # Find the winget.exe executable, grabbing the most recent version if multiple exist
        $wingetExe = Get-ChildItem -Path $windowsAppsPath -Filter "winget.exe" -Recurse -ErrorAction SilentlyContinue | 
                     Where-Object { $_.Directory.Name -match $appInstallerPattern } | 
                     Sort-Object LastWriteTime -Descending | 
                     Select-Object -First 1

        if ($wingetExe) {
            $wingetPath = $wingetExe.FullName
            Write-Log "Found Winget at: $wingetPath" "SUCCESS"
        }
    }

    # Fallback to standard Get-Command if run interactively by an admin
    if ([string]::IsNullOrEmpty($wingetPath)) {
        $wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue
        if ($wingetCommand) {
            $wingetPath = $wingetCommand.Source
            Write-Log "Found winget via system PATH: $wingetPath" "SUCCESS"
        } else {
            throw "Winget executable could not be found. Ensure App Installer is provisioned on this machine."
        }
    }

    # 2. Build installation arguments for SYSTEM scope
    # --scope machine enforces a system-wide install (required for Chrome to appear for all users)
    $wingetArgs = @(
        "install",
        "--id", "`"$AppId`"",
        "--exact",
        "--silent",
        "--scope", "machine",
        "--accept-package-agreements",
        "--accept-source-agreements"
    )

    Write-Log "Executing command: $wingetPath $($wingetArgs -join ' ')" "INFO"

    # 3. Execute installation
    $process = Start-Process -FilePath $wingetPath -ArgumentList $wingetArgs -Wait -NoNewWindow -PassThru
    $exitCode = $process.ExitCode

    # 4. Handle Exit Codes
    if ($exitCode -eq 0) {
        Write-Log "Application '$AppId' installed successfully." "SUCCESS"
    } elseif ($exitCode -in @(-1978335215, 2316632107)) {
        # Winget returns specific exit codes if the app is already installed
        Write-Log "Application '$AppId' is already installed on this machine." "SUCCESS"
    } else {
        throw "Winget failed with exit code $exitCode."
    }

} catch {
    Write-Log "Installation failed: $($_.Exception.Message)" "ERROR"
    exit 1
} finally {
    Write-Log "Script execution completed." "INFO"
    Write-Log "---------------------------------------------------" "INFO"
}
