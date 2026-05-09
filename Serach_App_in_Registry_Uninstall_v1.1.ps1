<#
.SYNOPSIS
    Searches the registry for matching applications and uninstalls all versions found.

.DESCRIPTION
    This script searches uninstall registry locations in HKLM
    using a partial application name match and executes the uninstall
    command for every matched application.

    A separate log file is created for each application version.

.AUTHOR
    Arghya Biswas
#>

# =========================
# Set Application Name Here
# =========================
$AppName = "7-zip"

# =========================
# Log Directory
# =========================
$LogDirectory = "C:\Temp"

if (-not (Test-Path $LogDirectory)) {

    New-Item `
        -Path $LogDirectory `
        -ItemType Directory `
        -Force | Out-Null
}

# Global Log File Variable
$script:LogFile = $null

# =========================
# Logging Function
# =========================
function Write-Log {

    param (
        [string]$Message,

        [ValidateSet("INFO","SUCCESS","WARN","ERROR","DEBUG")]
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $logEntry = "$timestamp [$Level] $Message"

    switch ($Level) {

        "INFO" {
            Write-Host $logEntry -ForegroundColor White
        }

        "SUCCESS" {
            Write-Host $logEntry -ForegroundColor Green
        }

        "WARN" {
            Write-Host $logEntry -ForegroundColor Yellow
        }

        "ERROR" {
            Write-Host $logEntry -ForegroundColor Red
        }

        "DEBUG" {
            Write-Host $logEntry -ForegroundColor Cyan
        }

        default {
            Write-Host $logEntry
        }
    }

    # Write to file if available
    if ($script:LogFile) {

        Add-Content `
            -Path $script:LogFile `
            -Value $logEntry
    }
}

# =========================
# Registry Paths
# =========================
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$foundApps = @()

Write-Log "Searching for applications matching: $AppName" "INFO"

# =========================
# Search Registry
# =========================
foreach ($path in $registryPaths) {

    Write-Log "Searching Registry Path: $path" "DEBUG"

    try {

        $apps = Get-ItemProperty `
            -Path $path `
            -ErrorAction SilentlyContinue

        foreach ($app in $apps) {

            if (
                $app.DisplayName -and
                $app.DisplayName -like "*$AppName*"
            ) {

                $uninstallCmd = if ($app.QuietUninstallString) {
                    $app.QuietUninstallString
                }
                else {
                    $app.UninstallString
                }

                if (-not [string]::IsNullOrWhiteSpace($uninstallCmd)) {

                    $foundApps += [PSCustomObject]@{
                        DisplayName      = $app.DisplayName

                        DisplayVersion   = if ($app.DisplayVersion) {
                            $app.DisplayVersion
                        }
                        else {
                            "Unknown"
                        }

                        Publisher        = if ($app.Publisher) {
                            $app.Publisher
                        }
                        else {
                            "Unknown"
                        }

                        UninstallCommand = $uninstallCmd
                    }
                }
            }
        }
    }
    catch {

        Write-Log "Failed to read registry path: $path" "ERROR"
        Write-Log $_.Exception.Message "ERROR"
    }
}

# =========================
# No Apps Found
# =========================
if ($foundApps.Count -eq 0) {

    Write-Log "No matching application found for: $AppName" "WARN"
    exit 1
}

Write-Log "Total Applications Found: $($foundApps.Count)" "SUCCESS"

# =========================
# Uninstall Applications
# =========================
foreach ($app in $foundApps) {

    # =========================
    # Create Per-Version Log File
    # =========================
    $sanitizedName = $app.DisplayName -replace '[\\/:*?""<>|]', '_'
    $sanitizedVersion = $app.DisplayVersion -replace '[\\/:*?""<>|]', '_'

    $script:LogFile = Join-Path `
        -Path $LogDirectory `
        -ChildPath "Uninstall_${sanitizedName}_${sanitizedVersion}.log"

    Write-Log "==================================================" "INFO"
    Write-Log "Script Started" "INFO"
    Write-Log "Log File         : $script:LogFile" "INFO"
    Write-Log "Display Name     : $($app.DisplayName)" "INFO"
    Write-Log "Display Version  : $($app.DisplayVersion)" "INFO"
    Write-Log "Publisher        : $($app.Publisher)" "INFO"
    Write-Log "==================================================" "INFO"

    $uninstallCommand = $app.UninstallCommand

    # =========================
    # Handle MSIEXEC
    # =========================
    if ($uninstallCommand -match '(?i)msiexec(\.exe)?') {

        Write-Log "MSIEXEC uninstall detected" "DEBUG"

        # Convert /I to /X
        $uninstallCommand = $uninstallCommand -replace '(?i)/I', '/X'

        # Add silent switches
        if ($uninstallCommand -notmatch '(?i)/quiet') {

            $uninstallCommand += " /quiet"
        }

        if ($uninstallCommand -notmatch '(?i)/qn') {

            $uninstallCommand += " /qn"
        }

        if ($uninstallCommand -notmatch '(?i)/norestart') {

            $uninstallCommand += " /norestart"
        }
    }

    Write-Log "Final Uninstall Command:" "INFO"
    Write-Log $uninstallCommand "INFO"

    try {

        # =========================
        # Parse Command
        # =========================
        if ($uninstallCommand -match '^"([^"]+)"\s*(.*)$') {

            $exe = $matches[1]
            $args = $matches[2]
        }
        else {

            $split = $uninstallCommand.Split(" ", 2)

            $exe = $split[0]

            $args = if ($split.Count -gt 1) {
                $split[1]
            }
            else {
                ""
            }
        }

        Write-Log "Executable : $exe" "DEBUG"
        Write-Log "Arguments  : $args" "DEBUG"

        # =========================
        # Execute Uninstall
        # =========================
        $process = Start-Process `
            -FilePath $exe `
            -ArgumentList $args `
            -Wait `
            -PassThru `
            -NoNewWindow

        Write-Log "Process Exit Code: $($process.ExitCode)" "INFO"

        switch ($process.ExitCode) {

            0 {
                Write-Log "Uninstall completed successfully" "SUCCESS"
            }

            1605 {
                Write-Log "Product already uninstalled" "WARN"
            }

            1618 {
                Write-Log "Another installation is already in progress" "WARN"
            }

            3010 {
                Write-Log "Uninstall successful. Restart required" "WARN"
            }

            default {
                Write-Log "Uninstall finished with exit code $($process.ExitCode)" "WARN"
            }
        }
    }
    catch {

        Write-Log "Failed to execute uninstall command" "ERROR"
        Write-Log $_.Exception.Message "ERROR"
    }

    Write-Log "==================================================" "INFO"
    Write-Log "Completed Processing Application" "SUCCESS"
    Write-Log "==================================================" "INFO"
}

Write-Log "All uninstall operations completed" "SUCCESS"